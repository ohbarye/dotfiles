require_relative "test_helper"

class BusinessHoursTest < Minitest::Test
  class FakeCalendar
    def initialize(non_business_dates: [])
      @non_business_dates = non_business_dates
    end

    def business_day?(date)
      return false if date.saturday? || date.sunday?

      !@non_business_dates.include?(date)
    end
  end

  def jst(y, m, d, h = 0, mi = 0, s = 0)
    Time.new(y, m, d, h, mi, s, "+09:00")
  end

  def test_same_day_interval_returns_elapsed_hours
    calendar = FakeCalendar.new
    start_time = jst(2026, 6, 15, 10, 0, 0) # Monday
    end_time = jst(2026, 6, 15, 15, 0, 0)
    assert_in_delta 5.0, BusinessHours.between(start_time, end_time, calendar), 0.001
  end

  def test_zero_when_end_before_start
    calendar = FakeCalendar.new
    assert_equal 0.0, BusinessHours.between(jst(2026, 6, 15, 15, 0), jst(2026, 6, 15, 10, 0), calendar)
  end

  def test_excludes_full_weekend_between_two_weekdays
    calendar = FakeCalendar.new
    # Friday 22:00 -> Monday 3:00, spanning Sat/Sun
    start_time = jst(2026, 6, 12, 22, 0, 0) # Friday
    end_time = jst(2026, 6, 15, 3, 0, 0) # Monday
    # Friday 22:00-24:00 = 2h, Sat/Sun excluded, Monday 0:00-3:00 = 3h
    assert_in_delta 5.0, BusinessHours.between(start_time, end_time, calendar), 0.001
  end

  def test_excludes_holiday_flagged_by_calendar
    calendar = FakeCalendar.new(non_business_dates: [Date.new(2026, 6, 15)]) # Monday treated as holiday
    start_time = jst(2026, 6, 15, 0, 0, 0)
    end_time = jst(2026, 6, 16, 10, 0, 0) # Tuesday 10:00
    assert_in_delta 10.0, BusinessHours.between(start_time, end_time, calendar), 0.001
  end

  def test_multi_day_business_span
    calendar = FakeCalendar.new
    # Monday 9:00 -> Wednesday 9:00 = 3 full business days = 72h
    start_time = jst(2026, 6, 15, 9, 0, 0)
    end_time = jst(2026, 6, 17, 9, 0, 0)
    assert_in_delta 48.0, BusinessHours.between(start_time, end_time, calendar), 0.001
  end
end
