require_relative "test_helper"
require "tmpdir"
require "date"
require "fileutils"

class HolidayCalendarTest < Minitest::Test
  SAMPLE_YAML = <<~YAML
    2026-01-01: 元日
    2026-01-12: 成人の日
  YAML

  def with_tmp_cache_path
    Dir.mktmpdir do |dir|
      yield File.join(dir, "holidays.yml")
    end
  end

  def test_weekend_is_never_a_business_day_even_without_holiday_data
    with_tmp_cache_path do |cache_path|
      calendar = HolidayCalendar.new(cache_path: cache_path, fetcher: -> { SAMPLE_YAML })
      # 2026-01-03 is a Saturday
      refute calendar.business_day?(Date.new(2026, 1, 3))
      # 2026-01-04 is a Sunday
      refute calendar.business_day?(Date.new(2026, 1, 4))
    end
  end

  def test_holiday_listed_in_data_is_not_a_business_day
    with_tmp_cache_path do |cache_path|
      calendar = HolidayCalendar.new(cache_path: cache_path, fetcher: -> { SAMPLE_YAML })
      refute calendar.business_day?(Date.new(2026, 1, 1))
      refute calendar.business_day?(Date.new(2026, 1, 12))
    end
  end

  def test_weekday_not_in_holiday_data_is_a_business_day
    with_tmp_cache_path do |cache_path|
      calendar = HolidayCalendar.new(cache_path: cache_path, fetcher: -> { SAMPLE_YAML })
      # 2026-01-02 is a Friday, not a holiday
      assert calendar.business_day?(Date.new(2026, 1, 2))
    end
  end

  def test_fetches_and_writes_cache_when_missing
    with_tmp_cache_path do |cache_path|
      calls = 0
      fetcher = -> { calls += 1; SAMPLE_YAML }
      HolidayCalendar.new(cache_path: cache_path, fetcher: fetcher)
      assert_equal 1, calls
      assert File.exist?(cache_path)
    end
  end

  def test_does_not_refetch_when_cache_is_fresh
    with_tmp_cache_path do |cache_path|
      File.write(cache_path, SAMPLE_YAML)
      calls = 0
      fetcher = -> { calls += 1; SAMPLE_YAML }
      HolidayCalendar.new(cache_path: cache_path, fetcher: fetcher)
      assert_equal 0, calls
    end
  end

  def test_refetches_when_cache_is_stale
    with_tmp_cache_path do |cache_path|
      File.write(cache_path, SAMPLE_YAML)
      stale_time = Time.now - (31 * 24 * 60 * 60)
      File.utime(stale_time, stale_time, cache_path)
      calls = 0
      fetcher = -> { calls += 1; SAMPLE_YAML }
      HolidayCalendar.new(cache_path: cache_path, fetcher: fetcher)
      assert_equal 1, calls
    end
  end
end
