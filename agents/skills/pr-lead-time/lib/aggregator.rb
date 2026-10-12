# frozen_string_literal: true

require_relative "bucketing"
require_relative "stats"

# Groups PR lead-time records into weekly/monthly buckets and computes
# median/mean/p75/p90/N and the share finished within WITHIN_HOURS for each of
# the three stages:
#   stage1: PR open -> base branch merge      (bucketed by merged_at)
#   stage2: base branch merge -> deploy       (bucketed by deployed_at)
#   stage3: PR open -> deploy ("total")       (bucketed by deployed_at)
module Aggregator
  WITHIN_HOURS = 6

  def self.build(records, granularity:)
    key_fn = granularity == :weekly ? Bucketing.method(:week_key) : Bucketing.method(:month_key)

    stage1 = Hash.new { |h, k| h[k] = [] }
    stage2 = Hash.new { |h, k| h[k] = [] }
    stage3 = Hash.new { |h, k| h[k] = [] }

    records.each do |r|
      stage1[key_fn.call(r[:merged_at])] << r[:stage1_hours] if r[:stage1_hours]
      next unless r[:deployed_at]

      deploy_key = key_fn.call(r[:deployed_at])
      stage2[deploy_key] << r[:stage2_hours]
      stage3[deploy_key] << r[:stage3_hours]
    end

    keys = (stage1.keys + stage2.keys + stage3.keys).uniq.sort
    keys.map do |key|
      {
        bucket: key,
        stage1: summarize(stage1[key]),
        stage2: summarize(stage2[key]),
        stage3: summarize(stage3[key])
      }
    end
  end

  def self.summarize(values)
    {
      median: Stats.median(values),
      mean: Stats.mean(values),
      p75: Stats.percentile(values, 0.75),
      p90: Stats.percentile(values, 0.9),
      within_6h: Stats.share_within(values, WITHIN_HOURS),
      n: values.length
    }
  end
end
