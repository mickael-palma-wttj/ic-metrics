# frozen_string_literal: true

module IcMetrics
  module Commands
    # Command to show analysis reports
    class ReportCommand < BaseCommand
      def validate!
        # No validation needed - username is optional
      end

      def run
        if @args.empty?
          list_available_reports
        else
          show_report(@args.first)
        end
      end

      private

      def list_available_reports
        puts "Available reports:"

        Dir.glob(File.join(@config.data_directory, "*")).each do |user_dir|
          next unless File.directory?(user_dir)

          username = File.basename(user_dir)
          analysis_file = File.join(user_dir, "analysis.json")

          next unless File.exist?(analysis_file)

          report_file = File.join(user_dir, "report.md")
          status = File.exist?(report_file) ? "Report available" : "Analysis only"
          puts "  #{username} - #{status}"
        end
      end

      def show_report(username)
        report_file = File.join(@config.data_directory, username, "report.md")

        raise Errors::DataNotFoundError, "No report found for #{username}. Run analysis first." unless File.exist?(report_file)

        puts File.read(report_file)
      end
    end
  end
end
