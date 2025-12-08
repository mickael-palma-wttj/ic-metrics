# frozen_string_literal: true

module IcMetrics
  module Services
    # Handles rate limiting for API requests
    class RateLimiter
      def initialize(delay:, disabled: false)
        @delay = delay
        @disabled = disabled
      end

      def wait
        sleep(@delay) unless @disabled
      end

      def self.standard
        new(delay: 0.1, disabled: ENV['DISABLE_SLEEP'] == 'true')
      end

      def self.search
        new(delay: 1.0, disabled: ENV['DISABLE_SLEEP'] == 'true')
      end
    end
  end
end
