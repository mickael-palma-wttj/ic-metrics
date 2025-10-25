# frozen_string_literal: true

module IcMetrics
  # Command-line interface for the IC Metrics application
  class CLI
    def initialize
      @config = nil
    end

    def run(args)
      case args[0]
      when "collect"
        ensure_config
        handle_collect_command(args[1..-1])
      when "analyze"
        ensure_config
        handle_analyze_command(args[1..-1])
      when "report"
        ensure_config
        handle_report_command(args[1..-1])
      when "help", nil
        show_help
      else
        puts "Unknown command: #{args[0]}"
        show_help
        exit 1
      end
    rescue Error => e
      puts "Error: #{e.message}"
      exit 1
    end

    private

    def ensure_config
      @config ||= Config.new
    end

    def handle_collect_command(args)
      if args.empty?
        puts "Error: Username is required"
        puts "Usage: ruby bin/ic_metrics collect <username> [--since=YYYY-MM-DD]"
        exit 1
      end

      username = args[0]
      since = extract_since_date(args)

      puts "Starting data collection for #{username}..."
      collector = DataCollector.new(@config)
      collector.collect_developer_data(username, since: since)
    end

    def handle_analyze_command(args)
      if args.empty?
        puts "Error: Username is required"
        puts "Usage: ruby bin/ic_metrics analyze <username>"
        exit 1
      end

      username = args[0]
      
      puts "Starting analysis for #{username}..."
      analyzer = ContributionAnalyzer.new(@config)
      analyzer.analyze_developer(username)
    end

    def handle_report_command(args)
      if args.empty?
        list_available_reports
      else
        show_report(args[0])
      end
    end

    def extract_since_date(args)
      since_arg = args.find { |arg| arg.start_with?("--since=") }
      return nil unless since_arg

      date_str = since_arg.split("=", 2)[1]
      Date.parse(date_str)
    rescue Date::Error
      puts "Error: Invalid date format. Use YYYY-MM-DD"
      exit 1
    end

    def list_available_reports
      puts "Available reports:"
      
      Dir.glob(File.join(@config.data_directory, "*")).each do |user_dir|
        next unless File.directory?(user_dir)
        
        username = File.basename(user_dir)
        report_file = File.join(user_dir, "report.md")
        analysis_file = File.join(user_dir, "analysis.json")
        
        if File.exist?(analysis_file)
          puts "  #{username} - #{File.exist?(report_file) ? 'Report available' : 'Analysis only'}"
        end
      end
    end

    def show_report(username)
      report_file = File.join(@config.data_directory, username, "report.md")
      
      unless File.exist?(report_file)
        puts "No report found for #{username}. Run analysis first."
        exit 1
      end
      
      puts File.read(report_file)
    end

    def show_help
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
          GITHUB_TOKEN    GitHub personal access token (required)
          GITHUB_ORG      GitHub organization name (default: WTTJ)
          DATA_DIRECTORY  Custom data storage path (default: ./data)
          
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
