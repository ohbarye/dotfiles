# frozen_string_literal: true

require "json"
require "open3"
require "time"

# Thin I/O wrapper around the `gh` CLI and `git` for a repo checked out at `repo_dir`.
# Not unit-tested directly (see SKILL.md); exercised via manual/integration runs.
class GithubClient
  # `gh pr list --json author` は GitHub App を `app/<slug>` 形式で返すため、
  # REST API 形式（`<slug>[bot]`）と両方を除外対象にする。
  DEFAULT_EXCLUDED_AUTHORS = %w[dependabot[bot] renovate[bot] app/dependabot app/renovate].freeze

  class Error < StandardError; end

  def initialize(repo_dir:, deploy_history_since:, excluded_authors: DEFAULT_EXCLUDED_AUTHORS, runner: self.class.method(:run))
    @repo_dir = repo_dir
    @deploy_history_since = deploy_history_since
    @excluded_authors = excluded_authors
    @runner = runner
    @deploy_branch_commits = {}
  end

  SEARCH_PAGE_LIMIT = 1000

  # Returns { records: [{ number:, author:, created_at:, merged_at:, merge_commit_sha: }],
  #           excluded_bot_count: Integer }
  # for PRs merged into `base_branch` within [since, until_date].
  def merged_pull_requests(base_branch:, since:, until_date:)
    all = fetch_merged_prs(base_branch, since, until_date)
    excluded_bot_count = all.count { |pr| @excluded_authors.include?(pr.dig("author", "login")) }
    records = all.filter_map do |pr|
      login = pr.dig("author", "login")
      next if @excluded_authors.include?(login)

      {
        number: pr["number"],
        author: login,
        created_at: Time.parse(pr["createdAt"]),
        merged_at: Time.parse(pr["mergedAt"]),
        merge_commit_sha: pr.dig("mergeCommit", "oid")
      }
    end
    { records: records, excluded_bot_count: excluded_bot_count }
  end

  # Finds the earliest time `sha` became reachable from `deploy_branch`, by
  # binary-searching the first-parent history of the deploy branch (chronological,
  # ascending) for the first commit that has `sha` as an ancestor. Returns nil if
  # `sha` has not landed on the deploy branch (as of the most recent fetched commit).
  def deployed_at(sha, deploy_branch:, not_before:)
    candidates = deploy_branch_commits(deploy_branch)
    # Narrow to commits at/after `not_before` first (cheap, no git calls), then
    # binary-search that range for the first ancestor (git calls; history is
    # monotonic since this repo only merge-commits into the deploy branch).
    start_index = candidates.bsearch_index { |c| c[:time] >= not_before } || candidates.length
    lo = start_index
    hi = candidates.length - 1
    result = nil
    while lo <= hi
      mid = (lo + hi) / 2
      if ancestor?(sha, candidates[mid][:sha])
        result = candidates[mid]
        hi = mid - 1
      else
        lo = mid + 1
      end
    end
    result && result[:time]
  end

  private

  # gh's search-backed `pr list` silently truncates at --limit with no
  # guaranteed chronological order, so a single query over a wide date range
  # can drop older PRs once the true count exceeds SEARCH_PAGE_LIMIT. Detect
  # that (result count hits the limit) and bisect the date range until each
  # window's true count fits, then merge.
  def fetch_merged_prs(base_branch, since, until_date)
    query = "is:merged base:#{base_branch} merged:#{since}..#{until_date}"
    out = gh("pr", "list", "--search", query, "--limit", SEARCH_PAGE_LIMIT.to_s,
      "--json", "number,author,createdAt,mergedAt,mergeCommit")
    batch = JSON.parse(out)
    return batch if batch.length < SEARCH_PAGE_LIMIT || since >= until_date

    mid = since + ((until_date - since).to_i / 2)
    fetch_merged_prs(base_branch, since, mid) + fetch_merged_prs(base_branch, mid + 1, until_date)
  end

  def deploy_branch_commits(deploy_branch)
    @deploy_branch_commits[deploy_branch] ||= begin
      git("fetch", "origin", deploy_branch, "--quiet")
      # Use an explicit JST offset: a bare "--since=YYYY-MM-DD" is parsed in the
      # host's local timezone by git, which can silently exclude same-day JST
      # commits when the two zones disagree.
      since_jst = "#{(@deploy_history_since - 1).iso8601}T00:00:00+09:00" # 1-day safety buffer
      out = git("log", "origin/#{deploy_branch}", "--first-parent",
        "--since=#{since_jst}", "--pretty=format:%H %cI", "--reverse")
      out.each_line.filter_map do |line|
        sha, iso = line.strip.split(" ", 2)
        next if sha.nil? || iso.nil?

        { sha: sha, time: Time.iso8601(iso) }
      end
    end
  end

  def ancestor?(sha, candidate_sha)
    _out, status = Open3.capture2("git", "-C", @repo_dir, "merge-base", "--is-ancestor", sha, candidate_sha)
    status.success?
  end

  def gh(*args)
    @runner.call("gh", *args, chdir: @repo_dir)
  end

  def git(*args)
    @runner.call("git", "-C", @repo_dir, *args, chdir: nil)
  end

  def self.run(*args, chdir: nil)
    opts = {}
    opts[:chdir] = chdir if chdir
    out, err, status = Open3.capture3(*args, **opts)
    raise Error, "#{args.join(" ")} failed: #{err}" unless status.success?

    out
  end
end
