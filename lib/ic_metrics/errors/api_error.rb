# frozen_string_literal: true

module IcMetrics
  module Errors
    # API errors
    class ApiError < Error
      attr_reader :status_code, :endpoint

      def initialize(message, status_code: nil, endpoint: nil)
        @status_code = status_code
        @endpoint = endpoint
        super(message)
      end
    end
  end
end
