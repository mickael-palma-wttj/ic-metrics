# frozen_string_literal: true

module IcMetrics
  module Analyzers
    # Analyzer for collaboration metrics
    class CollaborationAnalyzer
      def initialize(repositories)
        @repositories = repositories
      end

      def analyze
        all_prs = @repositories.values.flat_map { |repo| repo['pull_requests'] }
        all_reviews = @repositories.values.flat_map { |repo| repo['reviews'] }

        collaborators = Set.new
        all_prs.each { |pr| collaborators.add(pr['user']['login']) }
        all_reviews.each { |review| collaborators.add(review['user']['login']) }

        {
          unique_collaborators: collaborators.size - 1, # Exclude the developer themselves
          repositories_contributed_to: active_repositories_count,
          cross_repo_activity: cross_repo_activity?
        }
      end

      private

      def active_repositories_count
        @repositories.count do |_, data|
          data['commits'].any? || data['pull_requests'].any? || data['reviews'].any?
        end
      end

      def cross_repo_activity?
        @repositories.count { |_, data| data['commits'].any? } > 1
      end
    end
  end
end
