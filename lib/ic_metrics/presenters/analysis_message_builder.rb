# frozen_string_literal: true

module IcMetrics
  module Presenters
    # Builds the analysis message with inline CSV data for Dust API
    class AnalysisMessageBuilder
      def initialize(username, system_prompt, csv_data)
        @username = username
        @system_prompt = system_prompt
        @csv_data = csv_data
      end

      def build
        [
          @system_prompt,
          separator,
          header,
          csv_sections,
          separator,
          recommendations
        ].join("\n\n")
      end

      private

      def separator
        '---'
      end

      def header
        <<~HEADER
          # GitHub Contribution Analysis for #{@username}

          I'm providing GitHub contribution data in CSV format below.
        HEADER
      end

      def csv_sections
        @csv_data.map { |filename, content| csv_section(filename, content) }.join("\n\n")
      end

      def csv_section(filename, content)
        "## #{filename}\n\n```csv\n#{content}```"
      end

      def recommendations
        <<~TEXT
          Please analyze the CSV data above and generate a comprehensive report with:
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
