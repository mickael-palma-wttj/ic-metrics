# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module IcMetrics
  module Commands
    # Command to analyze CSV exports using Dust API
    class AnalyzeCsvCommand < BaseCommand
      def validate!
        # No strict validation - will show help if arguments missing
      end

      def run
        username = @args[0]
        output_file = @args[1]

        unless username
          show_help
          return
        end

        output_file ||= default_output_file(username)
        execute_analysis(username, output_file)
      end

      private

      def show_help
        puts "Analyze CSV exports using Dust AI"
        puts ""
        puts "USAGE:"
        puts "  ic_metrics analyze-csv <username> [output_file]"
        puts ""
        puts "This command will:"
        puts "  1. Load all CSV exports for the developer"
        puts "  2. Send them to Dust AI API with analysis prompt"
        puts "  3. Generate a comprehensive quality report"
        puts ""
        puts "REQUIREMENTS:"
        puts "  - DUST_API_KEY environment variable must be set"
        puts "  - DUST_WORKSPACE_ID environment variable must be set"
        puts "  - DUST_AGENT_ID environment variable must be set"
        puts "  - CSV exports must exist (run 'export' or 'export-advanced' first)"
        puts ""
        puts "Available users:"
        list_available_users
      end

      def list_available_users
        data_dir = @config.data_directory
        return puts "  No data found" unless Dir.exist?(data_dir)

        Dir.glob(File.join(data_dir, "*")).select { |d| File.directory?(d) }.each do |user_dir|
          username = File.basename(user_dir)
          csv_dir = File.join(user_dir, "csv_exports")
          puts "  #{username}" if Dir.exist?(csv_dir) && !Dir.empty?(csv_dir)
        end
      end

      def default_output_file(username)
        File.join(@config.data_directory, username, "AI_ANALYSIS_#{username}.md")
      end

      def execute_analysis(username, output_file)
        Services::AnalysisValidator.validate_dust_credentials!

        csv_dir = csv_directory(username)
        Services::AnalysisValidator.validate_csv_directory!(csv_dir)

        puts "Loading CSV data for #{username}..."
        csv_data = load_csv_files(csv_dir)

        puts "Loading analysis prompt..."
        prompt = load_analysis_prompt

        puts "\nSending data to Dust AI for analysis..."
        puts "This may take 30-60 seconds depending on data size..."

        credentials = load_credentials
        request = build_analysis_request(username, csv_data, prompt, output_file, credentials)

        service = Services::Dust::AnalysisService.new(@config)
        service.analyze(request)
      rescue Services::CredentialsError, Services::CsvNotFoundError => e
        puts "Error: #{e.message}"
        exit 1
      end

      def csv_directory(username)
        File.join(@config.data_directory, username, "csv_exports")
      end

      def load_credentials
        {
          api_key: ENV["DUST_API_KEY"],
          workspace_id: ENV["DUST_WORKSPACE_ID"],
          agent_id: ENV["DUST_AGENT_ID"]
        }
      end

      def build_analysis_request(username, csv_data, prompt, output_file, credentials)
        Services::AnalysisRequest.new(
          username: username,
          csv_data: csv_data,
          system_prompt: prompt,
          output_file: output_file,
          credentials: credentials
        )
      end

      def load_csv_files(csv_dir)
        files = Services::CsvFileRegistry.load_from_directory(csv_dir)
        files.each { |filename, content| puts "  ✓ Loaded #{filename} (#{content.lines.count} lines)" }
        files
      end

      def load_analysis_prompt
        prompt_file = File.expand_path("../../../prompts/csv-analysis.prompt.md", __FILE__)
        return File.read(prompt_file) if File.exist?(prompt_file)

        puts "Warning: Analysis prompt not found at #{prompt_file}"
        puts "Using basic prompt..."
        "Analyze the following CSV data and provide insights about code quality, patterns, and areas of concern."
      end
    end
  end
end
