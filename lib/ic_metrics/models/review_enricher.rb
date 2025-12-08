# frozen_string_literal: true

module IcMetrics
  module Models
    # Enriches PR reviews with comment bodies
    class ReviewEnricher
      def initialize(reviews, comments)
        @reviews = reviews
        @comments_by_review = comments.group_by { |c| c['pull_request_review_id'] }
      end

      def enrich
        @reviews.each do |review|
          enrich_review(review) if needs_enrichment?(review)
        end
        @reviews
      end

      private

      def needs_enrichment?(review)
        review['body'].to_s.strip.empty? && review['state'] == 'COMMENTED'
      end

      def enrich_review(review)
        comments = @comments_by_review[review['id']] || []
        review['body'] = format_comments(comments) if comments.any?
      end

      def format_comments(comments)
        comments.filter_map { |c| c['body'] }.join("\n---\n")
      end
    end
  end
end
