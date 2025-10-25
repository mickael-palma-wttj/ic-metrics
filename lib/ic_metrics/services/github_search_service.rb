# frozen_string_literal: true

module IcMetrics
  module Services
    # Service to handle GitHub search API pagination
    class GithubSearchService
      MAX_RESULTS = 1000
      PER_PAGE = 100

      def initialize(client)
        @client = client
      end

      # Search with automatic pagination
      # @param query [String] The GitHub search query
      # @return [Array<Hash>] Array of search result items
      def search_paged(query)
        results = []
        page = 1

        loop do
          response = fetch_page(query, page)
          break if response.empty?

          results.concat(response)
          break if results.size >= MAX_RESULTS

          page += 1
        end

        results
      end

      private

      def fetch_page(query, page)
        encoded = URI.encode_www_form_component(query)
        endpoint = "/search/issues?q=#{encoded}&page=#{page}&per_page=#{PER_PAGE}"
        
        data = @client.request(endpoint)
        data["items"] || []
      end
    end
  end
end
