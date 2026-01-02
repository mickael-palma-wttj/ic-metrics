# frozen_string_literal: true

module IcMetrics
  module Utils
    # Utility module for analyzing commit messages
    module CommitTypeAnalyzer
      CONVENTIONAL_COMMIT_PATTERN = /^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?:/

      module_function

      def conventional_commit?(message)
        message.match?(CONVENTIONAL_COMMIT_PATTERN)
      end

      def extract_type(message)
        return 'conventional' if conventional_commit?(message)
        return 'merge' if message.downcase.include?('merge')
        return 'fix' if message.downcase.match?(/fix|bug/)
        return 'feature' if message.downcase.match?(/feat|add|new/)

        'other'
      end
    end
  end
end
