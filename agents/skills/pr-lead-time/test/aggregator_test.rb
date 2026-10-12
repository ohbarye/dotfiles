require_relative "test_helper"
require_relative "../lib/aggregator"

class AggregatorTest < Minitest::Test
  def jst(y, m, d, h = 12)
    Time.new(y, m, d, h, 0, 0, "+09:00")
  end

  def test_buckets_by_month_and_computes_stage_stats
    records = [
      {
        merged_at: jst(2026, 6, 10), deployed_at: jst(2026, 6, 11),
        stage1_hours: 10.0, stage2_hours: 5.0, stage3_hours: 15.0
      },
      {
        merged_at: jst(2026, 6, 20), deployed_at: jst(2026, 6, 21),
        stage1_hours: 20.0, stage2_hours: 15.0, stage3_hours: 35.0
      },
      {
        # not yet deployed: contributes to stage1 only
        merged_at: jst(2026, 6, 25), deployed_at: nil,
        stage1_hours: 30.0, stage2_hours: nil, stage3_hours: nil
      }
    ]

    rows = Aggregator.build(records, granularity: :monthly)
    assert_equal 1, rows.length
    row = rows.first
    assert_equal "2026-06", row[:bucket]
    assert_equal 3, row[:stage1][:n]
    assert_in_delta 20.0, row[:stage1][:median], 0.001
    assert_equal 2, row[:stage2][:n]
    assert_in_delta 10.0, row[:stage2][:median], 0.001
    assert_equal 2, row[:stage3][:n]
  end

  def test_stage2_and_stage3_bucketed_by_deploy_month_not_merge_month
    records = [
      {
        merged_at: jst(2026, 6, 30), deployed_at: jst(2026, 7, 1),
        stage1_hours: 5.0, stage2_hours: 24.0, stage3_hours: 29.0
      }
    ]

    rows = Aggregator.build(records, granularity: :monthly)
    june = rows.find { |r| r[:bucket] == "2026-06" }
    july = rows.find { |r| r[:bucket] == "2026-07" }

    assert_equal 1, june[:stage1][:n]
    assert_equal 0, june[:stage2][:n]
    assert_equal 1, july[:stage2][:n]
    assert_equal 1, july[:stage3][:n]
  end

  def test_summary_includes_distribution_stats
    records = [2.0, 4.0, 6.0, 20.0].map do |h|
      {
        merged_at: jst(2026, 6, 10), deployed_at: jst(2026, 6, 11),
        stage1_hours: h, stage2_hours: h, stage3_hours: h
      }
    end

    stage2 = Aggregator.build(records, granularity: :monthly).first[:stage2]
    assert_in_delta 8.0, stage2[:mean], 0.001
    assert_in_delta 9.5, stage2[:p75], 0.001
    assert_in_delta 15.8, stage2[:p90], 0.001
    assert_in_delta 0.75, stage2[:within_6h], 0.001
  end
end
