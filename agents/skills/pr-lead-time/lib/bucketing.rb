# frozen_string_literal: true

require "date"
require "time"

# Buckets timestamps into JST calendar weeks (Monday-start) or calendar months,
# regardless of the timezone the given Time was constructed in.
module Bucketing
  JST_OFFSET = "+09:00"

  def self.month_key(time)
    jst_date = to_jst_date(time)
    format("%04d-%02d", jst_date.year, jst_date.month)
  end

  def self.week_key(time)
    jst_date = to_jst_date(time)
    monday = jst_date - (jst_date.wday.zero? ? 6 : jst_date.wday - 1)
    monday.iso8601
  end

  def self.to_jst_date(time)
    time.getlocal(JST_OFFSET).to_date
  end
end
