# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "base64"

module IcMetrics
  module Commands
    # Command to analyze CSV exports using Dust API
    class AnalyzeCsvCommand < BaseCommand
      def validate!
        # No strict validation - will show help if arguments missing
      end

      def run
        username = @args[0]
        output_file = @args[1]

        unless username
          show_help
          return
        end

        output_file ||= File.join(@config.data_directory, username, "AI_ANALYSIS_#{username}.md")
        analyze_csv_with_dust(username, output_file)
      end

      private

      def show_help
        puts "Analyze CSV exports using Dust AI"
        puts ""
        puts "USAGE:"
        puts "  ic_metrics analyze-csv <username> [output_file]"
        puts ""
        puts "This command will:"
        puts "  1. Load all CSV exports for the developer"
        puts "  2. Send them to Dust AI API with analysis prompt"
        puts "  3. Generate a comprehensive quality report"
        puts ""
        puts "REQUIREMENTS:"
        puts "  - DUST_API_KEY environment variable must be set"
        puts "  - DUST_WORKSPACE_ID environment variable must be set"
        puts "  - DUST_AGENT_ID environment variable must be set"
        puts "  - CSV exports must exist (run 'export' or 'export-advanced' first)"
        puts ""
        puts "Available users:"
        list_available_users
      end

      def list_available_users
        data_dir = @config.data_directory
        return puts "  No data found" unless Dir.exist?(data_dir)

        Dir.glob(File.join(data_dir, "*")).select { |d| File.directory?(d) }.each do |user_dir|
          username = File.basename(user_dir)
          csv_dir = File.join(user_dir, "csv_exports")
          puts "  #{username}" if Dir.exist?(csv_dir) && !Dir.empty?(csv_dir)
        end
      end

      def analyze_csv_with_dust(username, output_file)
        # Check environment variables
        api_key = ENV["DUST_API_KEY"]
        workspace_id = ENV["DUST_WORKSPACE_ID"]
        agent_id = ENV["DUST_AGENT_ID"]
        
        unless api_key && workspace_id && agent_id
          puts "Error: DUST_API_KEY, DUST_WORKSPACE_ID, and DUST_AGENT_ID environment variables must be set"
          puts ""
          puts "Get your Dust credentials from: https://dust.tt/w/[workspace]/developers"
          puts ""
          puts "Then add to your .env file:"
          puts "  DUST_API_KEY=your_api_key_here"
          puts "  DUST_WORKSPACE_ID=your_workspace_id_here"
          puts "  DUST_AGENT_ID=your_agent_id_here"
          exit 1
        end

        # Load CSV data
        csv_dir = File.join(@config.data_directory, username, "csv_exports")
        
        unless Dir.exist?(csv_dir)
          puts "Error: No CSV exports found for #{username}"
          puts "Run: ic_metrics export #{username}"
          exit 1
        end

        puts "Loading CSV data for #{username}..."
        csv_data = load_csv_files(csv_dir)
        
        if csv_data.empty?
          puts "Error: No CSV files found in #{csv_dir}"
          exit 1
        end

        puts "Loading analysis prompt..."
        prompt = load_analysis_prompt
        
        puts "\nSending data to Dust AI for analysis..."
        puts "This may take 30-60 seconds depending on data size..."
        
        result = call_dust_api(api_key, workspace_id, agent_id, prompt, csv_data, username)
        
        # Save analysis
        FileUtils.mkdir_p(File.dirname(output_file))
        File.write(output_file, result[:content])
        
        puts "\n✅ Analysis completed!"
        puts "Report saved to: #{output_file}"
        
        if result[:conversation_url]
          puts "\n🔗 View online: #{result[:conversation_url]}"
        end
        
        puts "\nYou can also view it locally with:"
        puts "  cat #{output_file}"
        puts "  or open it in your editor"
      end

      def load_csv_files(csv_dir)
        csv_data = {}
        
        csv_files = [
          "commits.csv",
          "commits_enhanced.csv",
          "pull_requests.csv",
          "reviews.csv",
          "issues.csv",
          "pr_comments.csv",
          "issue_comments.csv",
          "text_content_analysis.csv",
          "activity_timeline.csv",
          "summary.csv"
        ]

        csv_files.each do |filename|
          filepath = File.join(csv_dir, filename)
          if File.exist?(filepath)
            content = File.read(filepath)
            csv_data[filename] = content
            puts "  ✓ Loaded #{filename} (#{content.lines.count} lines)"
          end
        end

        csv_data
      end

      def load_analysis_prompt
        prompt_file = File.expand_path("../../../prompts/csv-analysis.prompt.md", __FILE__)
        
        unless File.exist?(prompt_file)
          puts "Warning: Analysis prompt not found at #{prompt_file}"
          puts "Using basic prompt..."
          return "Analyze the following CSV data and provide insights about code quality, patterns, and areas of concern."
        end

        File.read(prompt_file)
      end

      def call_dust_api(api_key, workspace_id, agent_id, system_prompt, csv_data, username)
        # First, upload CSV files and get file IDs
        puts "Uploading CSV files to Dust..."
        file_ids = upload_csv_files(api_key, workspace_id, csv_data)
        
        if file_ids.empty?
          return {
            content: "Error: Failed to upload CSV files",
            conversation_url: nil,
            conversation_id: nil
          }
        end
        
        puts "✓ Uploaded #{file_ids.size} CSV files"
        
        # Create conversation with file references
        uri = URI.parse("https://dust.tt/api/v1/w/#{workspace_id}/assistant/conversations")
        
        # Build content fragments with file IDs
        content_fragments = file_ids.map do |filename, file_id|
          {
            fileId: file_id,
            title: filename
          }
        end
        
        user_message = build_analysis_message_with_file_references(username, system_prompt, file_ids)
        
        request_body = {
          title: "IC Metrics Analysis: #{username}",
          visibility: "unlisted",
          message: {
            content: user_message,
            mentions: [{ configurationId: agent_id }],
            context: {
              origin: "api",
              timezone: "UTC",
              username: username,
              fullName: nil,
              email: nil,
              profilePictureUrl: nil
            },
            contentFragments: content_fragments
          }
        }.to_json

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{api_key}"
        request["Content-Type"] = "application/json"
        request.body = request_body

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        case response.code.to_i
        when 200, 201
          result = JSON.parse(response.body)
          conversation_id = result.dig("conversation", "sId")
          
          if conversation_id
            conversation_url = "https://dust.tt/w/#{workspace_id}/conversation/#{conversation_id}"
            puts "✓ Conversation created, waiting for response..."
            puts "  View online: #{conversation_url}"
            
            # Poll for the assistant's response
            content = get_dust_response(api_key, workspace_id, conversation_id)
            
            return {
              content: content,
              conversation_url: conversation_url,
              conversation_id: conversation_id
            }
          else
            return {
              content: "Error: Could not create conversation",
              conversation_url: nil,
              conversation_id: nil
            }
          end
        when 401
          return {
            content: "Error: Invalid Dust API key",
            conversation_url: nil,
            conversation_id: nil
          }
        when 404
          return {
            content: "Error: Workspace not found. Check DUST_WORKSPACE_ID",
            conversation_url: nil,
            conversation_id: nil
          }
        else
          return {
            content: "Error: Dust API returned #{response.code}: #{response.body}",
            conversation_url: nil,
            conversation_id: nil
          }
        end
      rescue StandardError => e
        return {
          content: "Error calling Dust API: #{e.message}\n#{e.backtrace.first(3).join("\n")}",
          conversation_url: nil,
          conversation_id: nil
        }
      end

      def upload_csv_files(api_key, workspace_id, csv_data)
        file_ids = {}
        
        csv_data.each do |filename, content|
          # Upload file to Dust
          uri = URI.parse("https://dust.tt/api/v1/w/#{workspace_id}/files")
          
          # Encode file content as base64
          encoded_content = Base64.strict_encode64(content)
          
          request_body = {
            fileName: filename,
            fileSize: content.bytesize,
            useCase: "conversation",
            contentType: "text/csv",
            content: encoded_content
          }.to_json
          
          request = Net::HTTP::Post.new(uri)
          request["Authorization"] = "Bearer #{api_key}"
          request["Content-Type"] = "application/json"
          request.body = request_body
          
          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(request)
          end
          
          if response.code.to_i == 200 || response.code.to_i == 201
            result = JSON.parse(response.body)
            file_id = result.dig("file", "id") || result.dig("file", "sId") || result["id"]
            
            if file_id
              file_ids[filename] = file_id
              puts "  ✓ Uploaded #{filename} (ID: #{file_id})"
            else
              puts "  ✗ Failed to get file ID for #{filename}"
              puts "    Response: #{response.body}"
            end
          else
            puts "  ✗ Failed to upload #{filename}: #{response.code}"
            puts "    Response: #{response.body}"
          end
        end
        
        file_ids
      rescue StandardError => e
        puts "Error uploading files: #{e.message}"
        puts e.backtrace.first(5).join("\n")
        {}
      end

      def build_analysis_message_with_file_references(username, system_prompt, file_ids_hash)
        message = "#{system_prompt}\n\n"
        message += "---\n\n"
        message += "# GitHub Contribution Analysis for #{username}\n\n"
        message += "I've attached #{file_ids_hash.size} CSV files containing GitHub contribution data:\n\n"
        
        file_ids_hash.each do |filename, file_id|
          message += "- #{filename} (File ID: #{file_id})\n"
        end
        
        message += "\nPlease analyze these attached CSV files and generate a comprehensive report with:\n"
        message += "1. Critical issues and red flags\n"
        message += "2. Work pattern analysis\n"
        message += "3. Quality metrics\n"
        message += "4. Positive highlights\n"
        message += "5. Prioritized recommendations\n"
        
        message
      end

      def build_analysis_message_with_attachments(username, system_prompt, csv_data)
        message = "#{system_prompt}\n\n"
        message += "---\n\n"
        message += "# GitHub Contribution Analysis for #{username}\n\n"
        message += "I'm providing GitHub contribution data in CSV format below.\n\n"
        
        # Include actual CSV data inline
        csv_data.each do |filename, content|
          lines = content.lines
          message += "## #{filename}\n\n"
          message += "```csv\n"
          
          # Include first 100 lines of each CSV (or all if less)
          if lines.count > 100
            message += lines[0...100].join
            message += "\n... (#{lines.count - 100} more lines truncated)\n"
          else
            message += content
          end
          
          message += "```\n\n"
        end
        
        message += "\n---\n\n"
        message += "Please analyze the CSV data above and generate a comprehensive report with:\n"
        message += "1. Critical issues and red flags\n"
        message += "2. Work pattern analysis\n"
        message += "3. Quality metrics\n"
        message += "4. Positive highlights\n"
        message += "5. Prioritized recommendations\n"
        
        message
      end

      def get_dust_response(api_key, workspace_id, conversation_id)
        uri = URI.parse("https://dust.tt/api/v1/w/#{workspace_id}/assistant/conversations/#{conversation_id}")
        
        max_attempts = 180  # Wait up to 3 minutes for analysis
        attempt = 0
        
        puts "Polling for agent response..."
        
        loop do
          sleep(2)  # Poll every 2 seconds
          attempt += 1
          
          request = Net::HTTP::Get.new(uri)
          request["Authorization"] = "Bearer #{api_key}"
          
          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(request)
          end
          
          if response.code.to_i == 200
            result = JSON.parse(response.body)
            messages = result.dig("conversation", "content")
            
            # Flatten nested arrays and ensure it's an array
            messages = Array(messages).flatten
            
            # Find the agent's message
            agent_message = messages.find do |m| 
              m.is_a?(Hash) && m["type"] == "agent_message"
            end
            
            if agent_message
              status = agent_message["status"]
              
              # Display status updates every 10 seconds
              if attempt % 5 == 0
                case status
                when "created"
                  puts "\n⏳ Agent preparing response..." if attempt == 5
                when "pending"
                  puts "\n🔄 Agent analyzing data..." if attempt == 10
                end
              end
              
              # If succeeded, extract content
              if status == "succeeded"
                puts "\n✓ Analysis complete! Extracting content..."
                
                # Check if content is directly available
                if agent_message["content"]
                  puts "✓ Content extracted (#{agent_message["content"].length} characters)"
                  return agent_message["content"]
                end
                
                # Fallback: Extract content from action array
                if agent_message["action"].is_a?(Array)
                  actions = agent_message["action"]
                  
                  # Look for generation action with content
                  generation_action = actions.find { |a| a["type"] == "generation" }
                  if generation_action && generation_action["content"]
                    return generation_action["content"]
                  end
                  
                  # Fallback: concatenate all content from actions
                  content_parts = actions.map { |a| a["content"] }.compact
                  return content_parts.join("\n\n") unless content_parts.empty?
                end
                
                # If we got here, succeeded but no content found
                return "Error: Agent succeeded but returned no content"
              elsif status == "failed"
                error_msg = agent_message.dig("error", "message") || "Unknown error"
                return "Error: Agent failed - #{error_msg}"
              elsif status == "cancelled"
                return "Error: Agent response was cancelled"
              end
              # Otherwise keep waiting (status is "created" or "pending")
            else
              # No agent message yet, keep waiting
              print "." if attempt % 5 == 0
            end
          else
            puts "\nWarning: API returned #{response.code} on attempt #{attempt}"
          end
          
          if attempt >= max_attempts
            return "Error: Timeout waiting for Dust response after #{max_attempts * 2} seconds"
          end
        end
      rescue StandardError => e
        "Error retrieving Dust response: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      end
    end
  end
end
