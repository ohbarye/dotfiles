---
name: pr-lead-time
description: Measures PR lead time (open -> base-branch merge -> deploy) in business hours (JST, weekends/public holidays excluded), aggregated weekly or monthly. Use when the user asks about PR/delivery lead time, "PRリードタイム", "デリバリーのリードタイム", KR1 progress ("開発着手から本番環境に届くまでの摩擦"), or wants to know how long PRs take to open->merge->deploy for a repo.
---

# PR Lead Time

Measures how long PRs take to move through delivery, split into three stages, all
in **business hours** (JST, Sat/Sun and Japanese public holidays excluded):

1. PR open -> merged into the base branch (e.g. `develop`)
2. base branch merge -> landed on the deploy branch (e.g. `main`)
3. total: PR open -> landed on the deploy branch

Results are aggregated weekly or monthly (median, mean, N per stage) so trends
can be tracked over time (e.g. for an OKR like "reduce PR lead time median by
30%").

## Prerequisites

- Run from inside a git checkout of the target repo (or pass `--repo-dir`).
- `gh` CLI authenticated (`gh auth status`) with access to the repo.
- Ruby (stdlib only, no gems/Bundler needed).

## Usage

```bash
ruby ~/.claude/skills/pr-lead-time/scripts/pr_lead_time.rb [options]
```

| Option | Default | Description |
|---|---|---|
| `--base-branch NAME` | `develop` | Branch PRs merge into (stage 1 -> stage 2 boundary) |
| `--deploy-branch NAME` | `main` | Branch that represents "deployed" |
| `--since DATE` | 3 months back (monthly) / 4 weeks back (weekly) | Start date, `YYYY-MM-DD`, inclusive |
| `--until DATE` | today | End date, `YYYY-MM-DD`, inclusive |
| `--weekly` / `--monthly` | monthly | Aggregation granularity |
| `--format markdown\|json` | markdown | Output format |
| `--repo-dir PATH` | cwd | Path to the git checkout |

Example:

```bash
cd ~/path/to/some-repo
ruby ~/.claude/skills/pr-lead-time/scripts/pr_lead_time.rb --monthly
ruby ~/.claude/skills/pr-lead-time/scripts/pr_lead_time.rb --since 2026-06-01 --until 2026-06-30 --weekly --format json
```

## How it works

- **PR list**: `gh pr list --search "is:merged base:<base-branch> merged:<since>..<until>"`.
  Because stacked-PR tools (e.g. `gh stack`) retarget each branch's base to the
  trunk branch before it merges, this correctly captures stacked PRs too —
  `createdAt` still reflects when the PR was first opened, so the full stack
  wait time is included.
- **Deploy time**: for each PR's merge commit, walk the deploy branch's
  first-parent history (chronological) and binary-search (via
  `git merge-base --is-ancestor`) for the earliest commit that contains it as
  an ancestor. That commit's date is the "deployed at" time. This assumes the
  base branch is merged into the deploy branch via merge commits (not squash) —
  if squash-merged, ancestry can't be determined and the PR's stage 2/3 are
  skipped (counted under "ancestry判定不能" in the output).
- **Business hours**: elapsed wall-clock time with any time falling on a
  Saturday, Sunday, or Japanese public holiday excluded. Holiday data comes
  from [holiday-jp/holiday_jp-ruby](https://github.com/holiday-jp/holiday_jp-ruby)'s
  `holidays.yml`, fetched once and cached under `cache/holidays.yml` (refetched
  if older than 30 days). Company-specific holidays (year-end/New Year, summer
  break, etc.) are **not** accounted for.
- **Bucketing**: stage 1 is grouped by the base-branch merge date; stages 2 and
  3 are grouped by the deploy date (not the merge date) — a PR merged near a
  week/month boundary can end up in a different bucket for stage 1 vs stage
  2/3. This is intentional: each stage's trend should reflect when that stage's
  event actually happened.
- **Excluded from all stats**: PRs authored by `dependabot[bot]` or
  `renovate[bot]` (maintenance bots; `gh` reports them as `app/dependabot` /
  `app/renovate`, and both spellings are excluded). PRs authored by dev-agent bots (e.g.
  `devin-ai-integration[bot]`, Claude Code) are **included** — they represent
  real development flow, not automated maintenance.
- **Excluded from stage 2/3 only**: PRs merged into the base branch but not
  yet found on the deploy branch as of the query's `--until` (still in
  flight). Stage 1 for these PRs is still counted.

## Development

Pure logic (`lib/business_hours.rb`, `lib/holiday_calendar.rb`, `lib/stats.rb`,
`lib/bucketing.rb`, `lib/aggregator.rb`) is unit-tested with `minitest`:

```bash
cd ~/.claude/skills/pr-lead-time
for f in test/*_test.rb; do ruby -Itest -Ilib "$f"; done
```

`lib/github_client.rb` (all `gh`/`git` I/O) is intentionally not unit-tested —
it's a thin wrapper exercised via real runs against an actual repo.
