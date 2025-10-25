# frozen_string_literal: true

module IcMetrics
  # Base error class for all IC Metrics errors
  class Error < StandardError; end
  
  # Configuration related errors
  class ConfigurationError < Error; end
  
  # Network and API related errors
  class NetworkError < Error; end
  
  # Generic API error with additional context
  class ApiError < NetworkError
    attr_reader :status_code, :endpoint

    def initialize(message, status_code: nil, endpoint: nil)
      @status_code = status_code
      @endpoint = endpoint
      super(message)
    end
  end

  # Specific API errors
  class ResourceNotFoundError < ApiError; end
  class RateLimitError < ApiError; end
  class AuthenticationError < ApiError; end
  
  # Data related errors
  class DataNotFoundError < Error; end
  class InvalidDateFormatError < Error; end
end
