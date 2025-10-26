# frozen_string_literal: true

module IcMetrics
  module Errors
    # Rate limit exceeded (403)
    class RateLimitError < ApiError; end
  end
end
