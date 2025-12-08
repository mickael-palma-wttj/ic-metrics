# frozen_string_literal: true

module IcMetrics
  # Command-line interface for the IC Metrics application
  class CLI
    def run(args)
      config = Config.new
      command = Commands::CommandFactory.create(args[0], config, args[1..] || [])
      command.execute
    rescue Errors::ConfigurationError => e
      puts "Configuration Error: #{e.message}"
      exit 1
    rescue Errors::RateLimitError => e
      puts 'Error: Rate limit exceeded. Please wait before retrying.'
      puts "Endpoint: #{e.endpoint}" if e.endpoint
      exit 1
    rescue Errors::AuthenticationError => e
      puts 'Error: Authentication failed. Please check your GITHUB_TOKEN.'
      puts "Endpoint: #{e.endpoint}" if e.endpoint
      exit 1
    rescue Errors::DataNotFoundError => e
      puts "Error: #{e.message}"
      exit 1
    rescue Errors::InvalidDateFormatError => e
      puts "Error: #{e.message}"
      exit 1
    rescue Errors::ApiError => e
      puts "Error: API request failed (#{e.status_code}): #{e.message}"
      puts "Endpoint: #{e.endpoint}" if e.endpoint
      exit 1
    rescue Error => e
      puts "Error: #{e.message}"
      exit 1
    end
  end
end
