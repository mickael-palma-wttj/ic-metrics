# frozen_string_literal: true

module IcMetrics
  module Utils
    # Builds GitHub search queries
    class GithubQueryBuilder
      def initialize(organization)
        @organization = organization
      end

      def for_user_activity(username, since: nil, type: nil, filter: nil)
        QueryParts.new
                  .add("org:#{@organization}")
                  .add_filter(filter, username)
                  .add_type(type)
                  .add_date_filter(since)
                  .to_s
      end

      def for_author(username, date_filter = nil)
        "org:#{@organization} author:#{username}#{date_filter}"
      end

      def for_pull_requests(username, date_filter = nil)
        "org:#{@organization} author:#{username} type:pr#{date_filter}"
      end

      def for_issues(username, date_filter = nil)
        "org:#{@organization} author:#{username} type:issue#{date_filter}"
      end

      # Builds search query parts fluently
      class QueryParts
        def initialize
          @parts = []
        end

        def add(part)
          @parts << part if part
          self
        end

        def add_filter(filter, username)
          return self unless filter && username

          add("#{filter}:#{username}")
        end

        def add_type(type)
          return self unless type

          add("type:#{type}")
        end

        def add_date_filter(since)
          return self unless since

          add("created:>=#{DateFilter.format_for_search(since)}")
        end

        def to_s
          @parts.join(' ')
        end
      end
    end
  end
end
