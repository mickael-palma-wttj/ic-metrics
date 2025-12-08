# frozen_string_literal: true

module IcMetrics
  module Services
    # Validates prerequisites for CSV analysis
    class AnalysisValidator
      def self.validate_dust_credentials!
        return if credentials_present?

        raise CredentialsError, credentials_error_message
      end

      def self.validate_csv_directory!(csv_dir)
        return if directory_exists_and_not_empty?(csv_dir)

        raise CsvNotFoundError, 'CSV exports not found. Run: ic_metrics export <username>'
      end

      def self.credentials_present?
        %w[DUST_API_KEY DUST_WORKSPACE_ID DUST_AGENT_ID].all? { |key| ENV[key]&.strip&.length&.positive? }
      end

      def self.directory_exists_and_not_empty?(path)
        Dir.exist?(path) && !Dir.empty?(path)
      end

      def self.credentials_error_message
        <<~ERROR
          Missing Dust API credentials. Set these environment variables:
          - DUST_API_KEY
          - DUST_WORKSPACE_ID
          - DUST_AGENT_ID

          Get credentials from: https://dust.tt/w/[workspace]/developers
        ERROR
      end
    end

    # Custom error classes
    class CredentialsError < StandardError; end
    class CsvNotFoundError < StandardError; end
  end
end
