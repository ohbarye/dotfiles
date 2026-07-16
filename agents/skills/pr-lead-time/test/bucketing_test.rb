require_relative "test_helper"

class BucketingTest < Minitest::Test
  def test_month_key_uses_jst_date
    # 2026-06-14T16:00:00Z == 2026-06-15T01:00:00+09:00
    time = Time.new(2026, 6, 14, 16, 0, 0, "+00:00")
    assert_equal "2026-06", Bucketing.month_key(time)
  end

  def test_month_key_for_last_day_of_month
    time = Time.new(2026, 6, 30, 23, 0, 0, "+09:00")
    assert_equal "2026-06", Bucketing.month_key(time)
  end

  def test_week_key_returns_monday_of_that_week
    # 2026-06-17 is a Wednesday; the Monday of that week is 2026-06-15
    time = Time.new(2026, 6, 17, 12, 0, 0, "+09:00")
    assert_equal "2026-06-15", Bucketing.week_key(time)
  end

  def test_week_key_for_sunday_belongs_to_previous_monday
    # 2026-06-21 is a Sunday; belongs to the week starting 2026-06-15
    time = Time.new(2026, 6, 21, 12, 0, 0, "+09:00")
    assert_equal "2026-06-15", Bucketing.week_key(time)
  end

  def test_week_key_for_monday_itself
    time = Time.new(2026, 6, 15, 0, 30, 0, "+09:00")
    assert_equal "2026-06-15", Bucketing.week_key(time)
  end
end
