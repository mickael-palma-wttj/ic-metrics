# frozen_string_literal: true

module IcMetrics
  module Services
    module Dust
      # Main service for analyzing CSV files with Dust API
      class AnalysisService
        def initialize(config, logger: AnalysisLogger.new)
          @config = config
          @logger = logger
        end

        def analyze(request)
          @logger.creating_conversation

          client = HttpClient.new(request.api_key, request.workspace_id)
          conversation_id = create_conversation(client, request)
          url = conversation_url(request.workspace_id, conversation_id)

          @logger.conversation_created(url)

          upload_content_fragments(client, conversation_id, request.csv_data)

          @logger.sending_message
          send_analysis_message(client, conversation_id, request)

          @logger.waiting_for_response
          response = poll_response(client, conversation_id)

          save_analysis(response, request.output_file)
          @logger.completed(request.output_file)

          build_result(response, url, conversation_id)
        rescue StandardError => e
          build_error_result(e)
        end

        private

        def create_conversation(client, request)
          response = client.create_conversation(
            title: "IC Metrics Analysis: #{request.username}",
            visibility: 'unlisted',
            blocking: true
          )

          extract_conversation_id(response)
        end

        def upload_content_fragments(client, conversation_id, csv_data)
          csv_data.each_with_index do |(filename, content), idx|
            @logger.uploading_fragment(idx + 1, csv_data.size, filename, content.bytesize)
            client.create_content_fragment(conversation_id, filename, content)
          end
          @logger.fragments_uploaded(csv_data.size)
        end

        def send_analysis_message(client, conversation_id, request)
          message_content = Presenters::AnalysisMessageBuilder.new(
            request.username,
            request.system_prompt
          ).build

          client.create_message(conversation_id, request.agent_id, message_content)
        end

        def extract_conversation_id(response)
          result = JSON.parse(response.body)
          conversation_id = result.dig('conversation', 'sId')
          raise 'Failed to create conversation' unless conversation_id

          conversation_id
        end

        def poll_response(client, conversation_id)
          ResponsePoller.new(client, conversation_id).fetch_response
        end

        def save_analysis(content, output_file)
          FileUtils.mkdir_p(File.dirname(output_file))
          File.write(output_file, content)
        end

        def conversation_url(workspace_id, conversation_id)
          "https://dust.tt/w/#{workspace_id}/conversation/#{conversation_id}"
        end

        def build_result(content, url, conversation_id)
          {
            content: content,
            conversation_url: url,
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
