# frozen_string_literal: true

module IcMetrics
  module Services
    module Dust
      # Main service for analyzing CSV files with Dust API
      class AnalysisService
        def initialize(config)
          @config = config
        end

        def analyze(request)
          puts 'Creating conversation with agent...'

          client = HttpClient.new(request.api_key, request.workspace_id)
          conversation_id = create_conversation(client, request)

          puts '✓ Conversation created, waiting for response...'
          display_conversation_url(request.workspace_id, conversation_id)

          response = poll_response(client, conversation_id)

          save_analysis(response, request.output_file)
          display_completion_message(request.output_file)

          build_result(response, request.workspace_id, conversation_id)
        rescue StandardError => e
          build_error_result(e)
        end

        private

        def create_conversation(client, request)
          message_content = build_message_content(request)
          response = client.create_conversation(request_body(request, message_content))

          extract_conversation_id(response)
        end

        def build_message_content(request)
          Presenters::AnalysisMessageBuilder.new(
            request.username,
            request.system_prompt,
            request.csv_data
          ).build
        end

        def request_body(request, message_content)
          {
            title: "IC Metrics Analysis: #{request.username}",
            visibility: 'unlisted',
            message: {
              content: message_content,
              mentions: [{ configurationId: request.agent_id }],
              context: message_context(request.username)
            }
          }
        end

        def message_context(username)
          {
            origin: 'api',
            timezone: 'UTC',
            username: username,
            fullName: nil,
            email: nil,
            profilePictureUrl: nil
          }
        end

        def extract_conversation_id(response)
          result = JSON.parse(response.body)
          conversation_id = result.dig('conversation', 'sId')
          raise 'Failed to create conversation' unless conversation_id

          conversation_id
        end

        def poll_response(client, conversation_id)
          poller = ResponsePoller.new(client, conversation_id)
          puts 'Polling for agent response...'
          poller.fetch_response
        end

        def save_analysis(content, output_file)
          FileUtils.mkdir_p(File.dirname(output_file))
          File.write(output_file, content)
        end

        def display_conversation_url(workspace_id, conversation_id)
          url = "https://dust.tt/w/#{workspace_id}/conversation/#{conversation_id}"
          puts "  View online: #{url}"
        end

        def display_completion_message(output_file)
          puts "\n✅ Analysis completed!"
          puts "Report saved to: #{output_file}"
          puts "\nYou can also view it locally with:"
          puts "  cat #{output_file}"
          puts '  or open it in your editor'
        end

        def build_result(content, workspace_id, conversation_id)
          {
            content: content,
            conversation_url: "https://dust.tt/w/#{workspace_id}/conversation/#{conversation_id}",
            conversation_id: conversation_id
          }
        end

        def build_error_result(error)
          {
            content: "Error: #{error.message}",
            conversation_url: nil,
            conversation_id: nil
          }
        end
      end
    end
  end
end
