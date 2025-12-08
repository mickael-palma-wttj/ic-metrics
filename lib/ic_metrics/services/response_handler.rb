# frozen_string_literal: true

module IcMetrics
  module Services
    # Handles HTTP response status codes and raises appropriate errors
    class ResponseHandler
      HTTP_STATUS_HANDLERS = {
        '200' => :handle_success,
        '404' => :handle_not_found,
        '403' => :handle_forbidden,
        '401' => :handle_unauthorized
      }.freeze

      class << self
        def handle(response, endpoint)
          handler = HTTP_STATUS_HANDLERS[response.code] || :handle_error
          send(handler, response, endpoint)
        end

        private

        def handle_success(response, _endpoint)
          response
        end

        def handle_not_found(_response, endpoint)
          raise Errors::ResourceNotFoundError.new(
            'Resource not found',
            status_code: 404,
            endpoint: endpoint
          )
        end

        def handle_forbidden(_response, endpoint)
          raise Errors::RateLimitError.new(
            'Rate limit exceeded or insufficient permissions',
            status_code: 403,
            endpoint: endpoint
          )
        end

        def handle_unauthorized(_response, endpoint)
          raise Errors::AuthenticationError.new(
            'Invalid GitHub token',
            status_code: 401,
            endpoint: endpoint
          )
        end

        def handle_error(response, endpoint)
          raise Errors::ApiError.new(
            "GitHub API error: #{response.body}",
            status_code: response.code.to_i,
            endpoint: endpoint
          )
        end
      end
    end
  end
end
