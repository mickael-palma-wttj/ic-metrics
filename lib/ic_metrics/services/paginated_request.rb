# frozen_string_literal: true

module IcMetrics
  module Services
    # Handles paginated API requests
    class PaginatedRequest
      def initialize(http_client, rate_limiter)
        @http_client = http_client
        @rate_limiter = rate_limiter
      end

      def fetch_all(endpoint, per_page: 100)
        PageEnumerator.new(endpoint, per_page, @http_client, @rate_limiter).to_a
      end

      # Enumerates through pages of API results
      class PageEnumerator
        include Enumerable

        def initialize(endpoint, per_page, http_client, rate_limiter)
          @endpoint = endpoint
          @per_page = per_page
          @http_client = http_client
          @rate_limiter = rate_limiter
        end

        def each(&block)
          page = 1
          loop do
            url = build_paginated_url(page)
            data = fetch_page(url)
            break if data.empty?

            data.each(&block)
            page += 1
            @rate_limiter.wait
          end
        end

        private

        def build_paginated_url(page)
          separator = @endpoint.include?('?') ? '&' : '?'
          "#{@endpoint}#{separator}page=#{page}&per_page=#{@per_page}"
        end

        def fetch_page(url)
          response = @http_client.get(url)
          JSON.parse(response.body)
        end
      end
    end
  end
end
