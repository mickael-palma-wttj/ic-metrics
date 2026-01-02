# frozen_string_literal: true

module IcMetrics
  module Services
    module Dust
      # Value object representing the result of an analysis
      class AnalysisResult
        attr_reader :content, :conversation_url, :conversation_id

        def initialize(content:, conversation_url:, conversation_id:)
          @content = content
          @conversation_url = conversation_url
          @conversation_id = conversation_id
        end

        def success?
          !@conversation_id.nil?
        end

        def to_h
          {
            content: @content,
            conversation_url: @conversation_url,
            conversation_id: @conversation_id
          }
        end

        def self.success(content:, workspace_id:, conversation_id:)
          url = ConversationUrl.new(workspace_id, conversation_id).to_s
          new(content: content, conversation_url: url, conversation_id: conversation_id)
        end

        def self.failure(error)
          new(content: "Error: #{error.message}", conversation_url: nil, conversation_id: nil)
        end
      end
    end
  end
end
