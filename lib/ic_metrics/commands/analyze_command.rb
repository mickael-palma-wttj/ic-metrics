# frozen_string_literal: true

module IcMetrics
  module Commands
    # Command to analyze collected contribution data
    class AnalyzeCommand < BaseCommand
      def validate!
        return if @args.any?

        abort_with_error('Username is required', usage_message)
      end

      def run
        username = @args.first

        puts "Starting analysis for #{username}..."
        ContributionAnalyzer.new(@config).analyze_developer(username)
      end

      private

      def usage_message
        'Usage: ruby bin/ic_metrics analyze <username>'
      end
    end
  end
end
