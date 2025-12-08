# frozen_string_literal: true

module IcMetrics
  module Services
    module Dust
      # Value object representing an agent message from Dust API
      class AgentMessage
        attr_reader :data

        def initialize(data)
          @data = data || {}
        end

        def self.from_response(response)
          messages = Array(response.dig('conversation', 'content')).flatten
          message_data = messages.find { |m| m.is_a?(Hash) && m['type'] == 'agent_message' }
          new(message_data)
        end

        def succeeded?
          status == 'succeeded'
        end

        def failed?
          status == 'failed'
        end

        def cancelled?
          status == 'cancelled'
        end

        def status
          @data['status']
        end

        def content
          @data['content'] || extract_from_actions
        end

        def error_message
          @data.dig('error', 'message') || 'Unknown error'
        end

        private

        def extract_from_actions
          actions = Array(@data['action'])
          generation = actions.find { |a| a['type'] == 'generation' }
          generation&.dig('content') || actions.filter_map { |a| a['content'] }.join("\n\n")
        end
      end
    end
  end
end
