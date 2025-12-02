# frozen_string_literal: true

module IcMetrics
  module Utils
    # Utility class for date filtering and formatting
    class DateFilter
      # Format a date for GitHub search queries
      # @param date [Date, Time, String] The date to format
      # @return [String] Date in YYYY-MM-DD format
      def self.format_for_search(date)
        normalize_date(date).strftime("%Y-%m-%d")
      end

      # Check if a timestamp is within range of since/until dates
      # @param timestamp [String] ISO8601 timestamp string
      # @param since_date [Date, Time, nil] The start date to compare against
      # @param until_date [Date, Time, nil] The end date to compare against
      # @return [Boolean] True if timestamp is within range
      def self.within_range?(timestamp, since_date, until_date = nil)
        time = Time.parse(timestamp)

        return false if since_date && time < normalize_time(since_date)
        return false if until_date && time > normalize_time(until_date)

        true
      end

      # Normalize input to a Date object
      # @param date [Date, Time, String] The date to normalize
      # @return [Date] Normalized date
      def self.normalize_date(date)
        date.is_a?(Date) ? date : Date.parse(date.to_s)
      end

      # Normalize input to a Time object
      # @param date [Date, Time, String] The date to normalize
      # @return [Time] Normalized time
      def self.normalize_time(date)
        date.is_a?(Date) ? date.to_time : date
      end
    end
  end
end
