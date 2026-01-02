# frozen_string_literal: true

module IcMetrics
  module Services
    # Service for finding available users with collected data
    class UserFinder
      def initialize(data_directory)
        @data_directory = data_directory
      end

      def available_users
        return [] unless Dir.exist?(@data_directory)

        Dir.glob(File.join(@data_directory, '*'))
           .select { |d| File.directory?(d) }
           .select { |d| File.exist?(File.join(d, 'contributions.json')) }
           .map { |d| File.basename(d) }
           .sort
      end

      def print_available_users
        users = available_users
        if users.empty?
          puts '  No data found'
        else
          users.each { |u| puts "  #{u}" }
        end
      end
    end
  end
end
