# frozen_string_literal: true

module IcMetrics
  module Analyzers
    # Analyzer for commit patterns and statistics
    class CommitAnalyzer
      def initialize(repositories)
        @commits = repositories.values.flat_map { |repo| repo["commits"] }
      end

      def analyze
        return {} if @commits.empty?

        {
          total_commits: @commits.size,
          avg_commits_per_day: average_per_day,
          commit_frequency: frequency_analysis,
          most_active_hours: active_hours,
          commit_message_analysis: message_analysis
        }
      end

      private

      def commit_dates
        @commit_dates ||= @commits.map { |c| Time.parse(c.dig("commit", "author", "date")) }
      end

      def average_per_day
        return 0 if commit_dates.empty?

        first_date = commit_dates.min
        last_date = commit_dates.max
        days = [(last_date - first_date) / (24 * 60 * 60), 1].max

        (commit_dates.size / days).round(2)
      end

      def frequency_analysis
        by_day = commit_dates.group_by { |date| date.strftime("%A") }
        by_hour = commit_dates.group_by(&:hour)

        {
          by_day_of_week: by_day.transform_values(&:count),
          by_hour: by_hour.transform_values(&:count)
        }
      end

      def active_hours
        commit_dates
          .group_by(&:hour)
          .transform_values(&:count)
          .sort_by { |_, count| -count }
          .first(3)
          .map(&:first)
      end

      def message_analysis
        messages = @commits.map { |commit| commit.dig("commit", "message") }
        conventional_count = messages.count { |msg| conventional_commit?(msg) }

        {
          avg_message_length: (messages.map(&:length).sum / messages.size.to_f).round(2),
          conventional_commits: conventional_count,
          conventional_commit_percentage: (conventional_count / messages.size.to_f * 100).round(2)
        }
      end

      def conventional_commit?(message)
        message.match?(/^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?:/)
      end
    end
  end
end
