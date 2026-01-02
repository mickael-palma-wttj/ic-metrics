# frozen_string_literal: true

module IcMetrics
  module Services
    # Registry of CSV files to be analyzed
    class CsvFileRegistry
      # Files from 'export' command
      BASE_CSV_FILES = %w[
        commits.csv
        pull_requests.csv
        reviews.csv
        issues.csv
        pr_comments.csv
        issue_comments.csv
        summary.csv
      ].freeze

      # Files from 'export-advanced' command
      ADVANCED_CSV_FILES = %w[
        commits_enhanced.csv
        text_content_analysis.csv
        activity_timeline.csv
      ].freeze

      CSV_FILES = (BASE_CSV_FILES + ADVANCED_CSV_FILES).freeze

      def self.files
        CSV_FILES
      end

      def self.load_from_directory(directory)
        loaded = CSV_FILES.each_with_object({}) do |filename, data|
          path = File.join(directory, filename)
          data[filename] = File.read(path) if File.exist?(path)
        end

        if loaded.empty?
          raise "No CSV files found in #{directory}. Run 'export' and/or 'export-advanced enhanced' first."
        end

        loaded
      end
    end
  end
end
