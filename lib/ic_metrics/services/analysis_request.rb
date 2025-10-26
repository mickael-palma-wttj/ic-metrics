# frozen_string_literal: true

module IcMetrics
  module Services
    # Encapsulates the analysis request with all required parameters
    class AnalysisRequest
      attr_reader :username, :csv_data, :system_prompt, :output_file

      def initialize(username:, csv_data:, system_prompt:, output_file:, credentials:)
        @username = username
        @csv_data = csv_data
        @system_prompt = system_prompt
        @output_file = output_file
        @credentials = credentials
      end

      def api_key
        @credentials[:api_key]
      end

      def workspace_id
        @credentials[:workspace_id]
      end

      def agent_id
        @credentials[:agent_id]
      end
    end
  end
end
