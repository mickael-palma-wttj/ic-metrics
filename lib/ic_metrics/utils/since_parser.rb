# frozen_string_literal: true

module IcMetrics
  module Utils
    # Parser for --since and --until command line arguments
    class SinceParser
      def initialize(args)
        @args = args
      end

      # Parse the --since argument from command line arguments
      # @return [Date, nil] Parsed date or nil if not provided
      # @raise [InvalidDateFormatError] If date format is invalid
      def parse
        parse_date('--since=')
      end

      # Parse the --until argument from command line arguments
      # @return [Date, nil] Parsed date or nil if not provided
      # @raise [InvalidDateFormatError] If date format is invalid
      def parse_until
        parse_date('--until=')
      end

      # Parse both since and until dates
      # @return [Hash] Hash with :since and :until keys
      def parse_range
        {
          since: parse,
          until: parse_until
        }
      end

      private

      def parse_date(prefix)
        arg = find_argument(prefix)
        return nil unless arg

        date_string = extract_date_string(arg)
        Date.parse(date_string)
      rescue Date::Error
        raise Errors::InvalidDateFormatError, "Invalid date format '#{date_string}'. Use YYYY-MM-DD"
      end

      def find_argument(prefix)
        @args.find { |a| a.start_with?(prefix) }
      end

      def extract_date_string(arg)
        arg.split('=', 2).last
      end
    end
  end
end
