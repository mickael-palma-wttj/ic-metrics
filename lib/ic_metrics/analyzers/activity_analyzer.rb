# frozen_string_literal: true

module IcMetrics
  module Analyzers
    # Analyzer for activity distribution across repositories
    class ActivityAnalyzer
      def initialize(repositories)
        @repositories = repositories
      end

      def analyze
        @repositories.map do |repo_name, repo_data|
          build_activity_summary(repo_name, repo_data)
        end.sort_by { |repo| -repo[:total_activity] }
      end

      private

      def build_activity_summary(repo_name, repo_data)
        activity_counts = calculate_activity_counts(repo_data)

        {
          repository: repo_name,
          **activity_counts,
          total_activity: activity_counts.values.sum
        }
      end

      def calculate_activity_counts(repo_data)
        %i[commits pull_requests reviews issues pr_comments issue_comments].each_with_object({}) do |key, counts|
          counts[key] = Array(repo_data[key.to_s]).size
        end
      end
    end
  end
end
