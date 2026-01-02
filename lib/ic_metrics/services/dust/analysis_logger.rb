# frozen_string_literal: true

module IcMetrics
  module Services
    module Dust
      # Handles console output for the analysis process
      class AnalysisLogger
        def creating_conversation
          puts 'Creating conversation...'
        end

        def conversation_created(url)
          puts '✓ Conversation created'
          puts "  View online: #{url}"
        end

        def uploading_fragment(index, total, filename, size)
          puts "  Uploading fragment #{index}/#{total}: #{filename} (#{size} bytes)"
        end

        def fragments_uploaded(count)
          puts "✓ #{count} content fragments uploaded"
        end

        def sending_message
          puts 'Sending analysis request to agent...'
        end

        def waiting_for_response
          puts 'Waiting for agent response...'
          puts 'Polling for agent response...'
        end

        def completed(output_file)
          puts "\n✅ Analysis completed!"
          puts "Report saved to: #{output_file}"
          puts "\nYou can also view it locally with:"
          puts "  cat #{output_file}"
          puts '  or open it in your editor'
        end
      end
    end
  end
end
