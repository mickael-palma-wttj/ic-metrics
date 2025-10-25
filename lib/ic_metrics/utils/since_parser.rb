# frozen_string_literal: true

module IcMetrics
  module Utils
    # Parser for --since command line argument
    class SinceParser
      def initialize(args)
        @args = args
      end

      # Parse the --since argument from command line arguments
      # @return [Date, nil] Parsed date or nil if not provided
      # @raise [InvalidDateFormatError] If date format is invalid
      def parse
        arg = find_since_argument
        return nil unless arg

        date_string = extract_date_string(arg)
        Date.parse(date_string)
      rescue Date::Error
        raise InvalidDateFormatError, "Invalid date format '#{date_string}'. Use YYYY-MM-DD"
      end

      private

      def find_since_argument
        @args.find { |a| a.start_with?("--since=") }
      end

      def extract_date_string(arg)
        arg.split("=", 2).last
      end
    end
  end
end
