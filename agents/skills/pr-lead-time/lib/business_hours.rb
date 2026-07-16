# frozen_string_literal: true

require "date"

# Computes elapsed hours between two times, excluding any time that falls on
# a non-business day (weekend or holiday) according to the given calendar.
# `calendar` must respond to `business_day?(date)`.
module BusinessHours
  JST_OFFSET = "+09:00"

  def self.between(start_time, end_time, calendar)
    start_jst = start_time.getlocal(JST_OFFSET)
    end_jst = end_time.getlocal(JST_OFFSET)
    return 0.0 if end_jst <= start_jst

    total = 0.0
    cursor = start_jst
    while cursor < end_jst
      next_midnight = Time.new(cursor.year, cursor.month, cursor.day, 0, 0, 0, JST_OFFSET) + (24 * 60 * 60)
      segment_end = [next_midnight, end_jst].min
      total += (segment_end - cursor) / 3600.0 if calendar.business_day?(cursor.to_date)
      cursor = segment_end
    end
    total
  end
end
