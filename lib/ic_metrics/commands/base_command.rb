# frozen_string_literal: true

module IcMetrics
  module Commands
    # Base class for all CLI commands
    class BaseCommand
      def initialize(config, args)
        @config = config
        @args = args
      end

      def execute
        validate!
        run
      end

      private

      def validate!
        raise NotImplementedError, "#{self.class} must implement #validate!"
      end

      def run
        raise NotImplementedError, "#{self.class} must implement #run"
      end

      def abort_with_error(*messages)
        messages.each { |msg| puts "Error: #{msg}" }
        exit 1
      end
    end
  end
end
