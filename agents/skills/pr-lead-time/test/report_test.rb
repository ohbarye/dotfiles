require_relative "test_helper"
require_relative "../lib/report"

class ReportTest < Minitest::Test
  def rows
    stage = {median: 4.0, mean: 8.0, p75: 9.5, p90: 16.2, within_6h: 0.75, n: 4}
    [{bucket: "2026-06", stage1: stage, stage2: stage, stage3: stage}]
  end

  def test_markdown_keeps_main_table_and_adds_distribution_table
    md = Report.to_markdown(rows, granularity: :monthly)
    main, dist = md.split("\n\n", 2)

    assert_includes main, "①中央値(h)"
    assert_includes main, "| 2026-06 | 4.0 | 8.0 | 4 |"
    assert_includes dist, "①p75(h)"
    assert_includes dist, "②p90(h)"
    assert_includes dist, "計6h以内(%)"
    assert_includes dist, "| 2026-06 | 9.5 | 16.2 | 75 | 9.5 | 16.2 | 75 | 9.5 | 16.2 | 75 |"
  end

  def test_distribution_table_shows_dash_for_empty_bucket
    empty = {median: nil, mean: nil, p75: nil, p90: nil, within_6h: nil, n: 0}
    md = Report.to_markdown([{bucket: "2026-06", stage1: empty, stage2: empty, stage3: empty}], granularity: :monthly)
    assert_includes md, "| 2026-06 | - | - | - | - | - | - | - | - | - |"
  end

  def test_json_contains_distribution_stats
    json = JSON.parse(Report.to_json(rows))
    assert_equal 9.5, json["rows"][0]["stage2"]["p75"]
  end
end
