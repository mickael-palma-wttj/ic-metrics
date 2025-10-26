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
            export <username> [output_dir]            Export collected data to CSV files
            export-advanced <subcommand> <username>   Advanced CSV export with text analysis
            analyze-csv <username> [output_file]      Analyze CSV exports using Dust AI
            help                                      Show this help message

          EXPORT SUBCOMMANDS:
            export-advanced enhanced  <username> [dir]   Enhanced commit analysis CSV
            export-advanced timeline  <username> [file]  Activity timeline CSV
            export-advanced analysis  <username> [file]  Text content analysis CSV
            export-advanced merged    <username> [file]  All data in single CSV

          ENVIRONMENT VARIABLES:
            GITHUB_TOKEN            GitHub personal access token (required)
            GITHUB_ORG              GitHub organization name (default: WTTJ)
            DATA_DIRECTORY          Custom data storage path (default: ./data)
            DISABLE_SLEEP           Disable rate limit sleep delays (default: false)
            MAX_PARALLEL_WORKERS    Number of parallel workers for data collection (default: 4)
            DUST_API_KEY            Dust AI API key (required for analyze-csv command)
            DUST_WORKSPACE_ID       Dust workspace ID (required for analyze-csv command)
            DUST_AGENT_ID           Dust agent configuration ID (required for analyze-csv command)
            
            You can set these in a .env file (recommended) or export them directly.

          EXAMPLES:
            ruby bin/ic_metrics collect john.doe --since=2024-01-01
            ruby bin/ic_metrics analyze john.doe
            ruby bin/ic_metrics report john.doe
            ruby bin/ic_metrics export john.doe
            ruby bin/ic_metrics export-advanced timeline john.doe
            ruby bin/ic_metrics analyze-csv john.doe
            ruby bin/ic_metrics report

          The tool will store data in the ./data directory and generate detailed
          analysis reports including commits, PRs, reviews, and collaboration metrics.
        HELP
      end
    end
  end
end
