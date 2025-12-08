# frozen_string_literal: true

module IcMetrics
  module Commands
    # Command to collect developer contribution data
    class CollectCommand < BaseCommand
      def validate!
        return if @args.any?

        abort_with_error('Username is required', usage_message)
      end

      def run
        username = @args.first
        date_range = parse_date_range

        puts "Starting data collection for #{username}..."
        DataCollector.new(@config).collect_developer_data(
          username,
          since: date_range[:since],
          until_date: date_range[:until]
        )
      end

      private

      def parse_date_range
        Utils::SinceParser.new(@args).parse_range
      rescue InvalidDateFormatError => e
        abort_with_error(e.message, usage_message)
      end

      def usage_message
        'Usage: ruby bin/ic_metrics collect <username> [--since=YYYY-MM-DD] [--until=YYYY-MM-DD]'
      end
    end
  end
end
