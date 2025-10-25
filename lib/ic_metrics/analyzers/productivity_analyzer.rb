# frozen_string_literal: true

module IcMetrics
  module Analyzers
    # Analyzer for productivity metrics
    class ProductivityAnalyzer
      def initialize(repositories)
        @repositories = repositories
      end

      def analyze
        all_commits = @repositories.values.flat_map { |repo| repo["commits"] }
        all_prs = @repositories.values.flat_map { |repo| repo["pull_requests"] }

        return default_metrics if all_commits.empty?

        commit_dates = all_commits.map { |commit| Time.parse(commit.dig("commit", "author", "date")) }
        time_range = calculate_time_range(commit_dates)

        {
          weekly_commit_avg: (all_commits.size / time_range[:weeks]).round(2),
          monthly_commit_avg: (all_commits.size / time_range[:months]).round(2),
          pr_creation_rate: (all_prs.size / time_range[:months]).round(2)
        }
      end

      private

      def default_metrics
        { weekly_commit_avg: 0, monthly_commit_avg: 0, pr_creation_rate: 0 }
      end

      def calculate_time_range(dates)
        first_date = dates.min
        last_date = dates.max

        {
          weeks: [(last_date - first_date) / (7 * 24 * 60 * 60), 1].max,
          months: [(last_date - first_date) / (30 * 24 * 60 * 60), 1].max
        }
      end
    end
  end
end
