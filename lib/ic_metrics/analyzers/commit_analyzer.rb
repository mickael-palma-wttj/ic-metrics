# frozen_string_literal: true

module IcMetrics
  module Analyzers
    # Analyzer for commit patterns and statistics
    class CommitAnalyzer
      HOURS_PER_DAY = 24
      MINUTES_PER_HOUR = 60
      SECONDS_PER_MINUTE = 60
      SECONDS_PER_DAY = HOURS_PER_DAY * MINUTES_PER_HOUR * SECONDS_PER_MINUTE
      TOP_ACTIVE_HOURS_COUNT = 3

      def initialize(repositories)
        @commits = repositories.values.flat_map { |repo| repo['commits'] }
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
        @commit_dates ||= @commits.map { |c| Time.parse(c.dig('commit', 'author', 'date')) }
      end

      def average_per_day
        return 0 if commit_dates.empty?

        days = calculate_duration_days
        (commit_dates.size / days).round(2)
      end

      def calculate_duration_days
        first_date = commit_dates.min
        last_date = commit_dates.max
        [(last_date - first_date) / SECONDS_PER_DAY, 1].max
      end

      def frequency_analysis
        by_day = commit_dates.group_by { |date| date.strftime('%A') }
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
          .first(TOP_ACTIVE_HOURS_COUNT)
          .map(&:first)
      end

      def message_analysis
        messages = @commits.map { |commit| commit.dig('commit', 'message') }
        return default_message_analysis if messages.empty?

        conventional_count = messages.count { |msg| conventional_commit?(msg) }

        {
          avg_message_length: calculate_average_length(messages),
          conventional_commits: conventional_count,
          conventional_commit_percentage: calculate_percentage(conventional_count, messages.size)
        }
      end

      def default_message_analysis
        { avg_message_length: 0, conventional_commits: 0, conventional_commit_percentage: 0 }
      end

      def calculate_average_length(messages)
        (messages.sum(&:length) / messages.size.to_f).round(2)
      end

      def calculate_percentage(count, total)
        (count / total.to_f * 100).round(2)
      end

      def conventional_commit?(message)
        message.match?(/^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?:/)
      end
    end
  end
end
