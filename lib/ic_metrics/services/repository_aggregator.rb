# frozen_string_literal: true

module IcMetrics
  module Services
    # Aggregates repositories from multiple contribution sources
    class RepositoryAggregator
      def initialize(github_client, query_builder)
        @client = github_client
        @query_builder = query_builder
      end

      def aggregate_user_repositories(username, since)
        log_start(username)

        repositories = collect_from_all_sources(username, since)
        unique_repositories = deduplicate(repositories)

        log_completion(username, unique_repositories.size)
        unique_repositories
      end

      private

      def collect_from_all_sources(username, since)
        date_filter = build_date_filter(since)

        [
          from_authored_code(username, date_filter),
          from_pull_requests(username, date_filter),
          from_issues(username, date_filter),
          from_reviews(username, since),
          from_pr_comments(username, since),
          from_issue_comments(username, since),
          from_user_activity(username)
        ].flatten
      end

      def deduplicate(repositories)
        repositories.uniq { |repo| repo['id'] }
      end

      def build_date_filter(since)
        since ? " created:>=#{Utils::DateFilter.format_for_search(since)}" : ''
      end

      def from_authored_code(username, date_filter)
        query = @query_builder.for_author(username, date_filter)
        @client.search_repositories(query)
      end

      def from_pull_requests(username, date_filter)
        query = @query_builder.for_pull_requests(username, date_filter)
        @client.search_repositories(query)
      end

      def from_issues(username, date_filter)
        query = @query_builder.for_issues(username, date_filter)
        @client.search_repositories(query)
      end

      def from_reviews(username, since)
        repo_names = @client.search_reviewed_prs(username, since: since)
        fetch_repository_details(repo_names)
      end

      def from_pr_comments(username, since)
        repo_names = @client.search_commented_prs(username, since: since)
        fetch_repository_details(repo_names)
      end

      def from_issue_comments(username, since)
        repo_names = @client.search_commented_issues(username, since: since)
        fetch_repository_details(repo_names)
      end

      def from_user_activity(username)
        @client.fetch_user_activity_repositories(username)
      end

      def fetch_repository_details(repo_names)
        repo_names.uniq.filter_map do |repo_name|
          @client.request("/repos/#{@client.organization}/#{repo_name}")
        rescue Error => e
          puts "Warning: Could not fetch details for repository #{repo_name}: #{e.message}"
          nil
        end
      end

      def log_start(username)
        puts "Searching for repositories with contributions from #{username}..."
      end

      def log_completion(username, count)
        puts "Found #{count} total repositories with contributions from #{username}"
      end
    end
  end
end
