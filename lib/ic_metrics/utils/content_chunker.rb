# frozen_string_literal: true

module IcMetrics
  module Utils
    # Utility module for chunking large content at line boundaries
    # Used to split content that exceeds Dust API fragment size limits
    module ContentChunker
      module_function

      # Splits content into chunks that don't exceed max_size bytes
      # Chunks are split at line boundaries to preserve data integrity
      #
      # @param content [String] The content to chunk
      # @param max_size [Integer] Maximum size in bytes for each chunk
      # @return [Array<String>] Array of content chunks
      def chunk(content, max_size)
        return [content] if content.bytesize <= max_size

        chunks = []
        current_chunk = +''

        content.each_line do |line|
          if would_exceed_limit?(current_chunk, line, max_size)
            chunks << current_chunk unless current_chunk.empty?
            current_chunk = handle_oversized_line(line, max_size)
          else
            current_chunk << line
          end
        end

        chunks << current_chunk unless current_chunk.empty?
        chunks
      end

      # Generates part names for chunked content
      # @param filename [String] Original filename
      # @param chunk_index [Integer] Zero-based chunk index
      # @param total_chunks [Integer] Total number of chunks
      # @return [String] Formatted part name
      def part_name(filename, chunk_index, total_chunks)
        return filename if total_chunks == 1

        "#{filename} (Part #{chunk_index + 1}/#{total_chunks})"
      end

      # Private helper methods
      def would_exceed_limit?(current_chunk, line, max_size)
        (current_chunk.bytesize + line.bytesize) > max_size
      end

      def handle_oversized_line(line, max_size)
        # If a single line exceeds max_size, we still include it
        # to avoid data loss, but it will be its own chunk
        line.bytesize > max_size ? line : line.dup
      end

      private_class_method :would_exceed_limit?, :handle_oversized_line
    end
  end
end
