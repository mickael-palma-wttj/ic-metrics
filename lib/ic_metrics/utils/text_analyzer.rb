# frozen_string_literal: true

module IcMetrics
  module Utils
    # Utility module for analyzing text content
    module TextAnalyzer
      module_function

      def word_count(text)
        text&.split&.size || 0
      end

      def line_count(text)
        text&.lines&.size || 0
      end

      def has_code_blocks?(text)
        text&.include?('```') || text&.include?('`') || false
      end

      def has_links?(text)
        text&.match?(%r{https?://}) || false
      end

      def has_mentions?(text)
        text&.include?('@') || false
      end
    end
  end
end
