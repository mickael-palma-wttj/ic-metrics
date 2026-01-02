# frozen_string_literal: true

module IcMetrics
  module Services
    # Service for loading contribution data from disk
    class ContributionLoader
      def initialize(data_directory)
        @data_directory = data_directory
      end

      def load(username)
        file = contribution_file(username)
        raise Errors::DataNotFoundError, username unless File.exist?(file)

        JSON.parse(File.read(file))
      end

      def exists?(username)
        File.exist?(contribution_file(username))
      end

      private

      def contribution_file(username)
        File.join(@data_directory, username, 'contributions.json')
      end
    end
  end
end
