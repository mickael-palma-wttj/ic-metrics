# frozen_string_literal: true

module IcMetrics
  module Services
    module Dust
      # Encapsulates HTTP communication with Dust API
      class HttpClient
        BASE_URL = "https://dust.tt/api/v1"

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
          execute_request(uri, request)
        end

        def build_request(method, uri, body)
          request_class = Net::HTTP.const_get(method.capitalize.to_s)
          request = request_class.new(uri)
          request["Authorization"] = "Bearer #{@api_key}"
          request["Content-Type"] = "application/json"
          request.body = body if body
          request
        end

        def execute_request(uri, request)
          Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
        end
      end
    end
  end
end
