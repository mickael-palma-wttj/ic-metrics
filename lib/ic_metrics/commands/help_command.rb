# frozen_string_literal: true

module IcMetrics
  module Commands
    # Command to show help message
    class HelpCommand < BaseCommand
      def validate!
        # No validation needed
      end

      def run
        puts <<~HELP
          IC Metrics - Developer Contribution Analysis Tool

          USAGE:
            ruby bin/ic_metrics <command> [options]

          COMMANDS:
            collect <username> [--since=YYYY-MM-DD]  Collect contribution data for a developer
            analyze <username>                        Analyze collected data and generate insights
            report [username]                         Show analysis report (or list all available)
            help                                      Show this help message

          ENVIRONMENT VARIABLES:
            GITHUB_TOKEN     GitHub personal access token (required)
            GITHUB_ORG       GitHub organization name (default: WTTJ)
            DATA_DIRECTORY   Custom data storage path (default: ./data)
            DISABLE_SLEEP    Disable rate limit sleep delays (default: false)
            
            You can set these in a .env file (recommended) or export them directly.

          EXAMPLES:
            ruby bin/ic_metrics collect john.doe --since=2024-01-01
            ruby bin/ic_metrics analyze john.doe
            ruby bin/ic_metrics report john.doe
            ruby bin/ic_metrics report

          The tool will store data in the ./data directory and generate detailed
          analysis reports including commits, PRs, reviews, and collaboration metrics.
        HELP
      end
    end
  end
end
