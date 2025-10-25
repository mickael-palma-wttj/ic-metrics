# frozen_string_literal: true

module IcMetrics
  module Models
    # Value object for repository data collection
    class RepositoryData
      def initialize(repo_name:, username:, client:, since: nil)
        @repo_name = repo_name
        @username = username
        @client = client
        @since = since
        @pull_requests = nil
      end

      def collect
        {
          commits: fetch_commits,
          pull_requests: fetch_pull_requests,
          reviews: fetch_reviews,
          issues: fetch_issues,
          pr_comments: fetch_pr_comments,
          issue_comments: fetch_issue_comments
        }
      end

      private

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
          @pull_requests.flat_map { |pr| fetch_user_reviews(pr) }
        end
      end

      def fetch_user_reviews(pr)
        reviews = @client.fetch_reviews(@repo_name, pr["number"])
        filter_user_reviews(reviews)
      end

      def filter_user_reviews(reviews)
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
        Utils::DateFilter.within_range?(timestamp, @since)
      end

      def log_and_fetch(resource_name)
        puts "  Fetching #{resource_name}..."
        yield
      rescue IcMetrics::Error => e
        puts "    Warning: #{e.message}"
        []
      end
    end
  end
end
