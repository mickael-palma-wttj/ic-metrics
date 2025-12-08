# frozen_string_literal: true

module IcMetrics
  module Services
    # Handles HTTP requests to external APIs
    class HttpClient
      BASE_URL = 'https://api.github.com'

      def initialize(token)
        @token = token
      end

      def get(endpoint, headers: {})
        uri = URI("#{BASE_URL}#{endpoint}")
        http = build_http_connection(uri)
        request = build_request(uri, headers)

        execute_with_error_handling(http, request, endpoint)
      end

      private

      def build_http_connection(uri)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = true
        end
      end

      def build_request(uri, headers)
        Net::HTTP::Get.new(uri).tap do |req|
          req['Authorization'] = "token #{@token}"
          req['Accept'] = 'application/vnd.github.v3+json'
          req['User-Agent'] = 'IcMetrics/1.0'
          headers.each { |key, value| req[key] = value }
        end
      end

      def execute_with_error_handling(http, request, endpoint)
        response = http.request(request)
        ResponseHandler.handle(response, endpoint)
      end
    end
  end
end
