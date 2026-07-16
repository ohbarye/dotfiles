#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "date"
require "time"

require_relative "../lib/holiday_calendar"
require_relative "../lib/business_hours"
require_relative "../lib/github_client"
require_relative "../lib/aggregator"
require_relative "../lib/report"

# Measures PR lead time (open -> base-branch merge -> deploy) in business hours
# (JST, weekends/holidays excluded), aggregated weekly or monthly.
class Cli
  Options = Struct.new(
    :repo_dir, :base_branch, :deploy_branch, :since, :until_date, :granularity, :format,
    keyword_init: true
  )

  def self.parse(argv)
    granularity = :monthly
    opts = Options.new(
      repo_dir: Dir.pwd,
      base_branch: "develop",
      deploy_branch: "main",
      granularity: granularity,
      format: :markdown
    )

    OptionParser.new do |o|
      o.banner = "Usage: pr_lead_time.rb [options]"
      o.on("--base-branch NAME", "PR merge target that starts stage 2 (default: develop)") { |v| opts.base_branch = v }
      o.on("--deploy-branch NAME", "Branch that represents 'deployed' (default: main)") { |v| opts.deploy_branch = v }
      o.on("--since DATE", "Start date (YYYY-MM-DD), inclusive") { |v| opts.since = Date.parse(v) }
      o.on("--until DATE", "End date (YYYY-MM-DD), inclusive") { |v| opts.until_date = Date.parse(v) }
      o.on("--weekly", "Aggregate by ISO week (Monday-start, JST)") { opts.granularity = :weekly }
      o.on("--monthly", "Aggregate by calendar month, JST (default)") { opts.granularity = :monthly }
      o.on("--format FORMAT", %w[markdown json], "Output format: markdown (default) or json") { |v| opts.format = v.to_sym }
      o.on("--repo-dir PATH", "Path to a git checkout (default: cwd)") { |v| opts.repo_dir = v }
    end.parse!(argv)

    apply_defaults(opts)
    opts
  end

  def self.apply_defaults(opts)
    opts.until_date ||= Date.today
    opts.since ||= if opts.granularity == :weekly
      opts.until_date - (4 * 7)
    else
      Date.new(opts.until_date.year, opts.until_date.month, 1) << 2 # 1st of month, 2 months back -> 3 month window
    end
  end

  def self.run(argv)
    opts = parse(argv)
    calendar = HolidayCalendar.new
    client = GithubClient.new(repo_dir: opts.repo_dir, deploy_history_since: opts.since)

    fetched = client.merged_pull_requests(
      base_branch: opts.base_branch, since: opts.since, until_date: opts.until_date
    )

    not_deployed = 0
    records = fetched[:records].map do |pr|
      deployed_at = client.deployed_at(pr[:merge_commit_sha], deploy_branch: opts.deploy_branch, not_before: pr[:merged_at])
      not_deployed += 1 if deployed_at.nil?

      stage1_hours = BusinessHours.between(pr[:created_at], pr[:merged_at], calendar)
      stage2_hours = deployed_at && BusinessHours.between(pr[:merged_at], deployed_at, calendar)
      stage3_hours = deployed_at && BusinessHours.between(pr[:created_at], deployed_at, calendar)

      pr.merge(deployed_at: deployed_at, stage1_hours: stage1_hours, stage2_hours: stage2_hours, stage3_hours: stage3_hours)
    end

    rows = Aggregator.build(records, granularity: opts.granularity)
    excluded = { bot_authored: fetched[:excluded_bot_count], not_deployed: not_deployed }

    output = opts.format == :json ? Report.to_json(rows, excluded: excluded) : Report.to_markdown(rows, granularity: opts.granularity, excluded: excluded)
    puts output
  end
end

Cli.run(ARGV) if $PROGRAM_NAME == __FILE__
