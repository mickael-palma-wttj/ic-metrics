# frozen_string_literal: true

module IcMetrics
  module Services
    module Dust
      # Polls Dust API until analysis is complete and returns result
      class ResponsePoller
        POLL_INTERVAL = 2
        MAX_ATTEMPTS = 180

        def initialize(client, conversation_id)
          @client = client
          @conversation_id = conversation_id
          @attempt = 0
        end

        def fetch_response
          poll_until_ready
        rescue StandardError => e
          error_message(e)
        end

        private

        def poll_until_ready
          loop do
            sleep(POLL_INTERVAL)
            @attempt += 1

            http_response = @client.get_conversation(@conversation_id)
            response_body = parse_response(http_response)
            agent_message = AgentMessage.from_response(response_body)

            return agent_message.content if agent_message.succeeded?
            return error_response(agent_message) if agent_message.failed? || agent_message.cancelled?

            report_progress(agent_message) if should_report_progress?
            raise_if_timeout
          end
        end

        def parse_response(http_response)
          JSON.parse(http_response.body)
        rescue JSON::ParserError => e
          raise "Failed to parse Dust API response: #{e.message}"
        end

        def should_report_progress?
          @attempt % 5 == 0
        end

        def report_progress(agent_message)
          case agent_message.status
          when "created"
            puts "\n⏳ Agent preparing response..." if @attempt == 5
          when "pending"
            puts "\n🔄 Agent analyzing data..." if @attempt == 10
          end
        end

        def error_response(agent_message)
          case agent_message.status
          when "failed"
            "Error: Agent failed - #{agent_message.error_message}"
          when "cancelled"
            "Error: Agent response was cancelled"
          else
            "Error: Unknown agent error"
          end
        end

        def raise_if_timeout
          return unless @attempt >= MAX_ATTEMPTS

          raise TimeoutError, "Timeout waiting for Dust response after #{MAX_ATTEMPTS * POLL_INTERVAL} seconds"
        end

        def error_message(error)
          "Error retrieving Dust response: #{error.message}\n#{error.backtrace.first(5).join("\n")}"
        end
      end
    end
  end
end
