# frozen_string_literal: true

module IcMetrics
  module Presenters
    # Builds the analysis message for Dust API (CSV data is uploaded as content fragments)
    class AnalysisMessageBuilder
      def initialize(username, system_prompt)
        @username = username
        @system_prompt = system_prompt
      end

      def build
        [
          @system_prompt,
          separator,
          header,
          separator,
          instructions
        ].join("\n\n")
      end

      private

      def separator
        '---'
      end

      def header
        <<~HEADER
          # GitHub Contribution Analysis for #{@username}

          I have uploaded GitHub contribution data as content fragments in CSV format.
          Please analyze all the uploaded CSV files.
        HEADER
      end

      def instructions
        <<~TEXT
          Please analyze the CSV data from the content fragments and generate a comprehensive report with:
          1. Critical issues and red flags
          2. Work pattern analysis
          3. Quality metrics
          4. Positive highlights
          5. Prioritized recommendations
        TEXT
      end
    end
  end
end
