# frozen_string_literal: true

module IcMetrics
  module Services
    module Dust
      # Value object for building Dust conversation URLs
      class ConversationUrl
        BASE = 'https://dust.tt/w'

        def initialize(workspace_id, conversation_id)
          @workspace_id = workspace_id
          @conversation_id = conversation_id
        end

        def to_s
          "#{BASE}/#{@workspace_id}/conversation/#{@conversation_id}"
        end
      end
    end
  end
end
