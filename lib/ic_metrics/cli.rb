# frozen_string_literal: true

module IcMetrics
  # Command-line interface for the IC Metrics application
  class CLI
    EXIT_FAILURE = 1

    def run(args)
      config = Config.new
      command = Commands::CommandFactory.create(args[0], config, args[1..] || [])
      command.execute
    rescue Errors::ConfigurationError => e
      handle_configuration_error(e)
    rescue Errors::RateLimitError => e
      handle_rate_limit_error(e)
    rescue Errors::AuthenticationError => e
      handle_authentication_error(e)
    rescue Errors::DataNotFoundError, Errors::InvalidDateFormatError => e
      handle_generic_error(e)
    rescue Errors::ApiError => e
      handle_api_error(e)
    rescue Error => e
      handle_generic_error(e)
    end

    private

    def handle_configuration_error(error)
      puts "Configuration Error: #{error.message}"
      exit EXIT_FAILURE
    end

    def handle_rate_limit_error(error)
      puts 'Error: Rate limit exceeded. Please wait before retrying.'
      print_endpoint(error)
      exit EXIT_FAILURE
    end

    def handle_authentication_error(error)
      puts 'Error: Authentication failed. Please check your GITHUB_TOKEN.'
      print_endpoint(error)
      exit EXIT_FAILURE
    end

    def handle_api_error(error)
      puts "Error: API request failed (#{error.status_code}): #{error.message}"
      print_endpoint(error)
      exit EXIT_FAILURE
    end

    def handle_generic_error(error)
      puts "Error: #{error.message}"
      exit EXIT_FAILURE
    end

    def print_endpoint(error)
      puts "Endpoint: #{error.endpoint}" if error.endpoint
    end
  end
end
