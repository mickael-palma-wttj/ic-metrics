# frozen_string_literal: true

module IcMetrics
  module Analyzers
    # Analyzer for code review patterns
    class ReviewAnalyzer
      def initialize(repositories)
        @reviews = repositories.values.flat_map { |repo| repo["reviews"] }
      end

      def analyze
        return {} if @reviews.empty?

        {
          total_reviews: @reviews.size,
          review_states: state_distribution,
          avg_reviews_per_day: average_per_day
        }
      end

      private

      def state_distribution
        @reviews.group_by { |review| review["state"] }.transform_values(&:count)
      end

      def average_per_day
        review_dates = @reviews.map { |r| Time.parse(r["submitted_at"]) }
        return 0 if review_dates.empty?

        first_date = review_dates.min
        last_date = review_dates.max
        days = [(last_date - first_date) / (24 * 60 * 60), 1].max

        (review_dates.size / days).round(2)
      end
    end
  end
end
