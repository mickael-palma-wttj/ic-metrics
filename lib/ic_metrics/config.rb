# frozen_string_literal: true

module IcMetrics
  # Configuration class to handle GitHub API settings
  class Config
    # Dust API content fragment size limit (500KB, with safety margin)
    MAX_FRAGMENT_SIZE = 500_000

    attr_reader :github_token, :organization, :data_directory

    def initialize
      @github_token = ENV.fetch('GITHUB_TOKEN', nil)
      @organization = ENV['GITHUB_ORG'] || 'WTTJ'
      @data_directory = ENV['DATA_DIRECTORY'] || File.expand_path('../../data', __dir__)

      validate_config
      ensure_data_directory
    end

    private

    def validate_config
      return if @github_token

      raise Errors::ConfigurationError, <<~MSG
        GITHUB_TOKEN environment variable is required.

        To set up:
        1. Create a GitHub Personal Access Token at https://github.com/settings/tokens
        2. Grant 'repo' and 'read:org' scopes
        3. Set the token: export GITHUB_TOKEN="your_token_here"
        4. Or create a .env file with: GITHUB_TOKEN=your_token_here
      MSG
    end

    def ensure_data_directory
      FileUtils.mkdir_p(@data_directory)
    end
  end
end
