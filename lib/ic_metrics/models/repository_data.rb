# frozen_string_literal: true

module IcMetrics
  module Models
    # Value object for repository data collection
    class RepositoryData
      def initialize(repo_name:, username:, client:, since: nil, until_date: nil, quiet: false)
        @repo_name = repo_name
        @username = username
        @client = client
        @since = since
        @until_date = until_date
        @pull_requests = nil
        @quiet = quiet
      end

      def collect
        # Parallelize independent data fetching operations
        futures = {
          commits: fetch_commits_async,
          pull_requests: fetch_pull_requests_async,
          issues: fetch_issues_async,
          pr_comments: fetch_pr_comments_async,
          issue_comments: fetch_issue_comments_async
        }
        
        # Wait for all futures to complete
        results = futures.transform_values(&:value)
        
        # Reviews depend on pull_requests, so fetch after PRs are ready
        results[:reviews] = fetch_reviews_with_prs(results[:pull_requests])
        
        # Apply until_date filter to all results
        filter_results_by_until_date(results)
      end

      private

      def filter_results_by_until_date(results)
        return results unless @until_date

        {
          commits: filter_commits(results[:commits]),
          pull_requests: filter_by_date(results[:pull_requests], "created_at"),
          issues: filter_by_date(results[:issues], "created_at"),
          reviews: filter_by_date(results[:reviews], "submitted_at"),
          pr_comments: filter_by_date(results[:pr_comments], "created_at"),
          issue_comments: filter_by_date(results[:issue_comments], "created_at")
        }
      end

      def filter_commits(commits)
        commits.select do |commit|
          date = commit.dig("commit", "author", "date")
          date && within_date_range?(date)
        end
      end

      def filter_by_date(items, date_field)
        items.select do |item|
          date = item[date_field]
          date && within_date_range?(date)
        end
      end

      def fetch_commits_async
        Concurrent::Future.execute { fetch_commits }
      end

      def fetch_pull_requests_async
        Concurrent::Future.execute { fetch_pull_requests }
      end

      def fetch_issues_async
        Concurrent::Future.execute { fetch_issues }
      end

      def fetch_pr_comments_async
        Concurrent::Future.execute { fetch_pr_comments }
      end

      def fetch_issue_comments_async
        Concurrent::Future.execute { fetch_issue_comments }
      end

      def fetch_reviews_with_prs(pull_requests)
        @pull_requests = pull_requests
        fetch_reviews
      end

      def fetch_commits
        log_and_fetch("commits") do
          @client.fetch_commits(@repo_name, @username, since: @since)
        end
      end

      def fetch_pull_requests
        @pull_requests ||= log_and_fetch("pull requests") do
          @client.fetch_pull_requests(@repo_name, author: @username, since: @since)
        end
      end

      def fetch_reviews
        log_and_fetch("reviews") do
          @pull_requests.flat_map { |pr| fetch_user_reviews_for_pr(pr) }
        end
      end

      def fetch_user_reviews_for_pr(pr)
        all_reviews = @client.fetch_reviews(@repo_name, pr["number"])
        filter_by_user_and_date(all_reviews)
      end

      def filter_by_user_and_date(reviews)
        reviews
          .select { |review| review["user"]["login"] == @username }
          .select { |review| within_date_range?(review["submitted_at"]) }
      end

      def fetch_issues
        created = log_and_fetch("created issues") do
          @client.fetch_issues(@repo_name, creator: @username, since: @since)
        end
        
        assigned = log_and_fetch("assigned issues") do
          @client.fetch_issues(@repo_name, assignee: @username, since: @since)
        end
        
        (created + assigned).uniq { |issue| issue["id"] }
      end

      def fetch_pr_comments
        log_and_fetch("PR comments") do
          @client.fetch_pr_comments_by_user(@repo_name, @username, since: @since)
        end
      end

      def fetch_issue_comments
        log_and_fetch("issue comments") do
          @client.fetch_issue_comments_by_user(@repo_name, @username, since: @since)
        end
      end

      def within_date_range?(timestamp)
        Utils::DateFilter.within_range?(timestamp, @since, @until_date)
      end

      def log_and_fetch(resource_name)
        puts "  ⏳ Fetching #{resource_name}..." unless @quiet
        
        result = yield
        
        count = result.is_a?(Array) ? result.size : 0
        puts "  ✓ Fetched #{count} #{resource_name}" unless @quiet
        
        result
      rescue IcMetrics::Error => e
        puts "  ⚠️  Warning: #{e.message}" unless @quiet
        []
      end
    end
  end
end
