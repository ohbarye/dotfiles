# frozen_string_literal: true

require "date"
require "fileutils"
require "net/http"

# Determines whether a given Date is a Japanese business day (not a weekend,
# not a public holiday). Holiday data is fetched from holiday-jp/holiday_jp-ruby
# and cached locally so repeated runs don't hit the network.
class HolidayCalendar
  HOLIDAYS_URL = "https://raw.githubusercontent.com/holiday-jp/holiday_jp-ruby/refs/heads/master/holidays.yml"
  CACHE_TTL_SECONDS = 30 * 24 * 60 * 60
  DEFAULT_CACHE_PATH = File.expand_path("../cache/holidays.yml", __dir__)

  def initialize(cache_path: DEFAULT_CACHE_PATH, fetcher: self.class.method(:fetch_from_network))
    @cache_path = cache_path
    @fetcher = fetcher
    @holidays = load_holidays
  end

  def business_day?(date)
    return false if date.saturday? || date.sunday?

    !@holidays.include?(date)
  end

  def self.fetch_from_network
    Net::HTTP.get(URI(HOLIDAYS_URL))
  end

  private

  def load_holidays
    ensure_cache!
    parse(File.read(@cache_path))
  end

  def ensure_cache!
    return if File.exist?(@cache_path) && !cache_stale?

    content = @fetcher.call
    FileUtils.mkdir_p(File.dirname(@cache_path))
    File.write(@cache_path, content)
  end

  def cache_stale?
    (Time.now - File.mtime(@cache_path)) > CACHE_TTL_SECONDS
  end

  def parse(text)
    text.each_line.with_object({}) do |line, holidays|
      line = line.strip
      next if line.empty? || !line.include?(":")

      date_str, = line.split(":", 2)
      holidays[Date.parse(date_str)] = true
    end
  end
end
