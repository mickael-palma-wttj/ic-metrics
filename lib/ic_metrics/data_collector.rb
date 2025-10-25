# frozen_string_literal: true

module IcMetrics
  # Data collector to fetch and store developer contribution data
  class DataCollector
    def initialize(config)
      @config = config
      @client = GithubClient.new(config)
      @data_dir = config.data_directory
    end

    # Collect all contribution data for a developer
    def collect_developer_data(username, since: nil)
      puts "Collecting data for developer: #{username}"
      
      developer_dir = File.join(@data_dir, username)
      FileUtils.mkdir_p(developer_dir) unless Dir.exist?(developer_dir)
      
      puts "Finding repositories where #{username} has contributed..."
      repositories = @client.fetch_user_repositories(username, since: since)
      
      if repositories.empty?
        puts "No repositories found with contributions from #{username}"
        puts "This could mean:"
        puts "  - The user hasn't contributed to any repositories in #{@config.organization}"
        puts "  - The user's contributions are in private repositories you don't have access to"
        puts "  - The username is incorrect"
        return create_empty_data_structure(username)
      end
      
      puts "Found #{repositories.size} repositories with contributions from #{username}"
      
      all_data = {
        developer: username,
        organization: @config.organization,
        collected_at: Time.now.iso8601,
        repositories: {},
        summary: {
          total_commits: 0,
          total_prs: 0,
          total_reviews: 0,
          total_issues: 0,
          total_pr_comments: 0,
          total_issue_comments: 0
        }
      }
      
      repositories.each_with_index do |repo, index|
        repo_name = repo["name"]
        puts "Processing repository #{index + 1}/#{repositories.size}: #{repo_name}"
        
        repo_data = collect_repository_data(repo_name, username, since)
        all_data[:repositories][repo_name] = repo_data
        
        # Update summary
        all_data[:summary][:total_commits] += repo_data[:commits].size
        all_data[:summary][:total_prs] += repo_data[:pull_requests].size
        all_data[:summary][:total_reviews] += repo_data[:reviews].size
        all_data[:summary][:total_issues] += repo_data[:issues].size
        all_data[:summary][:total_pr_comments] += repo_data[:pr_comments].size
        all_data[:summary][:total_issue_comments] += repo_data[:issue_comments].size
      end
      
      # Save collected data
      save_data(developer_dir, "contributions.json", all_data)
      
      puts "Data collection completed!"
      puts "Summary:"
      puts "  - Total commits: #{all_data[:summary][:total_commits]}"
      puts "  - Total PRs: #{all_data[:summary][:total_prs]}"
      puts "  - Total reviews: #{all_data[:summary][:total_reviews]}"
      puts "  - Total issues: #{all_data[:summary][:total_issues]}"
      puts "  - Total PR comments: #{all_data[:summary][:total_pr_comments]}"
      puts "  - Total issue comments: #{all_data[:summary][:total_issue_comments]}"
      
      all_data
    end

    private

    def collect_repository_data(repo_name, username, since)
      puts "  Fetching commits..."
      commits = fetch_with_error_handling do
        @client.fetch_commits(repo_name, username, since: since)
      end
      
      puts "  Fetching pull requests..."
      pull_requests = fetch_with_error_handling do
        @client.fetch_pull_requests(repo_name, author: username, since: since)
      end
      
      puts "  Fetching reviews..."
      reviews = []
      pull_requests.each do |pr|
        pr_reviews = fetch_with_error_handling do
          @client.fetch_reviews(repo_name, pr["number"])
        end
        # Filter reviews by username and date
        user_reviews = pr_reviews.select { |review| review["user"]["login"] == username }
        if since
          since_time = since.is_a?(Date) ? since.to_time : since
          user_reviews = user_reviews.select do |review|
            submitted_at = Time.parse(review["submitted_at"])
            submitted_at >= since_time
          end
        end
        reviews.concat(user_reviews)
      end
      
      puts "  Fetching issues..."
      created_issues = fetch_with_error_handling do
        @client.fetch_issues(repo_name, creator: username, since: since)
      end
      
      assigned_issues = fetch_with_error_handling do
        @client.fetch_issues(repo_name, assignee: username, since: since)
      end
      
      # Merge and deduplicate issues
      all_issues = (created_issues + assigned_issues).uniq { |issue| issue["id"] }
      
      puts "  Fetching PR comments..."
      pr_comments = fetch_with_error_handling do
        @client.fetch_pr_comments_by_user(repo_name, username, since: since)
      end
      
      puts "  Fetching issue comments..."
      issue_comments = fetch_with_error_handling do
        @client.fetch_issue_comments_by_user(repo_name, username, since: since)
      end
      
      {
        commits: commits,
        pull_requests: pull_requests,
        reviews: reviews,
        issues: all_issues,
        pr_comments: pr_comments,
        issue_comments: issue_comments
      }
    end

    def fetch_with_error_handling(&block)
      block.call
    rescue Error => e
      puts "    Warning: #{e.message}"
      []
    end

    def create_empty_data_structure(username)
      {
        developer: username,
        organization: @config.organization,
        collected_at: Time.now.iso8601,
        repositories: {},
        summary: {
          total_commits: 0,
          total_prs: 0,
          total_reviews: 0,
          total_issues: 0,
          total_pr_comments: 0,
          total_issue_comments: 0
        }
      }
    end

    def save_data(directory, filename, data)
      filepath = File.join(directory, filename)
      File.write(filepath, JSON.pretty_generate(data))
      puts "Data saved to: #{filepath}"
    end
  end
end
