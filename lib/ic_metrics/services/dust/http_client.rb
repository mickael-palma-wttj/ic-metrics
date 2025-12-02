# frozen_string_literal: true

module IcMetrics
  module Services
    module Dust
      # Encapsulates HTTP communication with Dust API
      class HttpClient
        BASE_URL = "https://dust.tt/api/v1"
        MAX_RETRIES = 3
        RETRY_DELAY = 2

        def initialize(api_key, workspace_id)
          @api_key = api_key
          @workspace_id = workspace_id
        end

        def create_conversation(request_body)
          post("assistant/conversations", request_body)
        end

        def get_conversation(conversation_id)
          get("assistant/conversations/#{conversation_id}")
        end

        private

        def post(endpoint, body)
          make_request(:post, endpoint, body.to_json)
        end

        def get(endpoint)
          make_request(:get, endpoint)
        end

        def make_request(method, endpoint, body = nil)
          uri = URI.parse("#{BASE_URL}/w/#{@workspace_id}/#{endpoint}")
          request = build_request(method, uri, body)
          execute_with_retry(uri, request)
        end

        def build_request(method, uri, body)
          request_class = Net::HTTP.const_get(method.capitalize.to_s)
          request = request_class.new(uri)
          request["Authorization"] = "Bearer #{@api_key}"
          request["Content-Type"] = "application/json"
          request.body = body if body
          request
        end

        def execute_with_retry(uri, request)
          retries = 0
          begin
            execute_request(uri, request)
          rescue Errno::ECONNRESET, OpenSSL::SSL::SSLError, Net::OpenTimeout, Net::ReadTimeout => e
            retries += 1
            if retries <= MAX_RETRIES
              puts "  ⚠️  Connection error (attempt #{retries}/#{MAX_RETRIES}): #{e.message}"
              puts "  ⏳ Retrying in #{RETRY_DELAY * retries} seconds..."
              sleep(RETRY_DELAY * retries)
              retry
            else
              raise e
            end
          end
        end

        def execute_request(uri, request)
          http = Net::HTTP.new(uri.hostname, uri.port)
          http.use_ssl = true
          http.open_timeout = 30
          http.read_timeout = 120
          http.request(request)
        end
      end
    end
  end
end
