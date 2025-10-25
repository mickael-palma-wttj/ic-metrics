# frozen_string_literal: true

module IcMetrics
  module Commands
    # Command to collect developer contribution data
    class CollectCommand < BaseCommand
      def validate!
        return if @args.any?

        abort_with_error("Username is required", usage_message)
      end

      def run
        username = @args.first
        since_date = parse_since_date

        puts "Starting data collection for #{username}..."
        DataCollector.new(@config).collect_developer_data(username, since: since_date)
      end

      private

      def parse_since_date
        Utils::SinceParser.new(@args).parse
      rescue InvalidDateFormatError => e
        abort_with_error(e.message, usage_message)
      end

      def usage_message
        "Usage: ruby bin/ic_metrics collect <username> [--since=YYYY-MM-DD]"
      end
    end
  end
end
