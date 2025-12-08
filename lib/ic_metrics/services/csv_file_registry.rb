# frozen_string_literal: true

module IcMetrics
  module Services
    # Registry of CSV files to be analyzed
    class CsvFileRegistry
      CSV_FILES = [
        'commits.csv',
        'commits_enhanced.csv',
        'pull_requests.csv',
        'reviews.csv',
        'issues.csv',
        'pr_comments.csv',
        'issue_comments.csv',
        'text_content_analysis.csv',
        'activity_timeline.csv',
        'summary.csv'
      ].freeze

      def self.files
        CSV_FILES
      end

      def self.load_from_directory(directory)
        CSV_FILES.each_with_object({}) do |filename, data|
          path = File.join(directory, filename)
          data[filename] = File.read(path) if File.exist?(path)
        end
      end
    end
  end
end
