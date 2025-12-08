# frozen_string_literal: true

module IcMetrics
  module Analyzers
    # Analyzer for pull request patterns and statistics
    class PrAnalyzer
      HOURS_PER_DAY = 24
      MINUTES_PER_HOUR = 60
      SECONDS_PER_MINUTE = 60
      SECONDS_PER_DAY = HOURS_PER_DAY * MINUTES_PER_HOUR * SECONDS_PER_MINUTE

      def initialize(repositories)
        @prs = repositories.values.flat_map { |repo| repo['pull_requests'] }
      end

      def analyze
        return {} if @prs.empty?

        {
          total_prs: @prs.size,
          pr_states: state_distribution,
          avg_pr_size: average_size,
          pr_merge_rate: merge_rate,
          avg_time_to_merge: average_merge_time
        }
      end

      private

      def state_distribution
        @prs.group_by { |pr| pr['state'] }.transform_values(&:count)
      end

      def average_size
        sizes = @prs.map { |pr| pr_size(pr) }
        return 0 if sizes.empty?

        (sizes.sum / sizes.size.to_f).round(2)
      end

      def pr_size(pr)
        (pr['additions'] || 0) + (pr['deletions'] || 0)
      end

      def merge_rate
        return 0 if @prs.empty?

        merged_count = @prs.count { |pr| pr['merged_at'] }
        calculate_percentage(merged_count, @prs.size)
      end

      def average_merge_time
        merged_prs = @prs.select { |pr| pr['merged_at'] }
        return 0 if merged_prs.empty?

        total_days = merged_prs.sum { |pr| days_to_merge(pr) }
        (total_days / merged_prs.size).round(2)
      end

      def days_to_merge(pr)
        created = Time.parse(pr['created_at'])
        merged = Time.parse(pr['merged_at'])
        (merged - created) / SECONDS_PER_DAY
      end

      def calculate_percentage(count, total)
        (count / total.to_f * 100).round(2)
      end
    end
  end
end
