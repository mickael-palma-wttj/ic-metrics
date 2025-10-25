# frozen_string_literal: true

module IcMetrics
  # GitHub API client for fetching contribution data
  class GithubClient
    BASE_URL = "https://api.github.com"
    
    def initialize(config)
      @token = config.github_token
      @organization = config.organization
      @disable_sleep = ENV["DISABLE_SLEEP"] == "true"
    end

    # Fetch all repositories for the organization
    def fetch_repositories
      get_paginated("/orgs/#{@organization}/repos")
    end

    # Fetch repositories where a specific user has contributed
    def fetch_user_repositories(username, since: nil)
      puts "Searching for repositories with contributions from #{username}..."
      
      # Build date filter for search queries
      date_filter = since ? " created:>=#{format_date_for_search(since)}" : ""
      
      # Search for repositories where the user has commits
      search_repos = search_repositories("org:#{@organization} author:#{username}#{date_filter}")
      
      # Also search for repositories where the user has PRs
      pr_repos = search_repositories("org:#{@organization} author:#{username} type:pr#{date_filter}")
      
      # Also search for repositories where the user has issues
      issue_repos = search_repositories("org:#{@organization} author:#{username} type:issue#{date_filter}")
      
      # Get repositories where user reviewed PRs
      reviewed_repo_names = search_reviewed_prs(username, since: since)
      
      # Get repositories where user commented on PRs
      commented_pr_repo_names = search_commented_prs(username, since: since)
      
      # Get repositories where user commented on issues
      commented_issue_repo_names = search_commented_issues(username, since: since)
      
      # Get additional repositories from user activity
      activity_repos = fetch_user_activity_repositories(username)
      
      # Fetch repository details for repos found by name only
      additional_repos = []
      all_repo_names = (reviewed_repo_names + commented_pr_repo_names + commented_issue_repo_names).uniq
      
      all_repo_names.each do |repo_name|
        begin
          repo_data = JSON.parse(make_request("/repos/#{@organization}/#{repo_name}").body)
          additional_repos << repo_data
        rescue Error => e
          puts "Warning: Could not fetch details for repository #{repo_name}: #{e.message}"
        end
      end
      
      # Combine and deduplicate all repositories
      all_repos = (search_repos + pr_repos + issue_repos + activity_repos + additional_repos).uniq { |repo| repo["id"] }
      
      puts "Found #{all_repos.size} total repositories with contributions from #{username}"
      all_repos
    end

    # Search repositories using GitHub search API
    def search_repositories(query)
      results = []
      page = 1
      
      loop do
        encoded_query = URI.encode_www_form_component(query)
        endpoint = "/search/repositories?q=#{encoded_query}&page=#{page}&per_page=100"
        
        response = make_request(endpoint)
        data = JSON.parse(response.body)
        
        break if data["items"].nil? || data["items"].empty?
        
        results.concat(data["items"])
        
        # GitHub search API has a limit of 1000 results
        break if results.size >= data["total_count"] || results.size >= 1000
        
        page += 1
        
        # Respect rate limits - search API has stricter limits
        sleep(1) unless @disable_sleep
      end
      
      results
    rescue Error => e
      puts "Warning: Repository search failed - #{e.message}"
      puts "Falling back to fetching all organization repositories"
      fetch_repositories
    end

    # Get repositories where user has been active (alternative approach using events API)
    def fetch_user_activity_repositories(username)
      puts "Fetching user activity to find additional repositories..."
      
      # Get user's public events to find repositories they've interacted with
      events = get_paginated("/users/#{username}/events/public")
      
      repo_names = events
        .select { |event| event["repo"] && event["repo"]["name"].start_with?("#{@organization}/") }
        .map { |event| event["repo"]["name"].split("/").last }
        .uniq
      
      puts "Found #{repo_names.size} additional repositories from user activity"
      
      # Fetch repository details for each found repo
      repositories = []
      repo_names.each do |repo_name|
        begin
          repo_data = JSON.parse(make_request("/repos/#{@organization}/#{repo_name}").body)
          repositories << repo_data
        rescue Error => e
          puts "Warning: Could not fetch details for repository #{repo_name}: #{e.message}"
        end
      end
      
      repositories
    rescue Error => e
      puts "Warning: Could not fetch user activity - #{e.message}"
      []
    end

    # Fetch commits for a specific repository and author
    def fetch_commits(repo_name, author, since: nil)
      params = { author: author }
      params[:since] = since.iso8601 if since
      
      query_string = URI.encode_www_form(params)
      get_paginated("/repos/#{@organization}/#{repo_name}/commits?#{query_string}")
    end

    # Fetch pull requests for a repository
    def fetch_pull_requests(repo_name, author: nil, state: "all", since: nil)
      params = { state: state }
      query_string = URI.encode_www_form(params)
      
      prs = get_paginated("/repos/#{@organization}/#{repo_name}/pulls?#{query_string}")
      
      # Filter by author if specified
      prs = prs.select { |pr| pr["user"]["login"] == author } if author
      
      # Filter by date if specified
      if since
        since_time = since.is_a?(Date) ? since.to_time : since
        prs = prs.select do |pr|
          created_at = Time.parse(pr["created_at"])
          created_at >= since_time
        end
      end
      
      prs
    end

    # Fetch reviews for a specific pull request
    def fetch_reviews(repo_name, pr_number)
      get_paginated("/repos/#{@organization}/#{repo_name}/pulls/#{pr_number}/reviews")
    end

    # Fetch review comments for a specific pull request
    def fetch_review_comments(repo_name, pr_number)
      get_paginated("/repos/#{@organization}/#{repo_name}/pulls/#{pr_number}/comments")
    end

      # Search for pull requests where the user was a reviewer
    def search_reviewed_prs(username, since: nil)
      date_filter = since ? " created:>=#{format_date_for_search(since)}" : ""
      query = "org:#{@organization} reviewed-by:#{username} type:pr#{date_filter}"
      
      results = []
      page = 1
      
      loop do
        encoded_query = URI.encode_www_form_component(query)
        endpoint = "/search/issues?q=#{encoded_query}&page=#{page}&per_page=100"
        
        response = make_request(endpoint)
        data = JSON.parse(response.body)
        
        break if data["items"].nil? || data["items"].empty?
        
        results.concat(data["items"])
        
        break if results.size >= data["total_count"] || results.size >= 1000
        
        page += 1
        sleep(1) unless @disable_sleep
      end      # Extract unique repository names
      repo_names = results
        .map { |pr| pr["repository_url"]&.split("/")&.last }
        .compact
        .uniq
      
      puts "Found #{repo_names.size} repositories where #{username} has reviewed PRs"
      repo_names
    rescue Error => e
      puts "Warning: PR review search failed - #{e.message}"
      []
    end

    # Search for pull requests where the user has commented
    def search_commented_prs(username, since: nil)
      date_filter = since ? " created:>=#{format_date_for_search(since)}" : ""
      query = "org:#{@organization} commenter:#{username} type:pr#{date_filter}"
      
      results = []
      page = 1
      
      loop do
        encoded_query = URI.encode_www_form_component(query)
        endpoint = "/search/issues?q=#{encoded_query}&page=#{page}&per_page=100"
        
        response = make_request(endpoint)
        data = JSON.parse(response.body)
        
        break if data["items"].nil? || data["items"].empty?
        
        results.concat(data["items"])
        
        break if results.size >= data["total_count"] || results.size >= 1000
        
        page += 1
        sleep(1) unless @disable_sleep
      end
      
      # Extract unique repository names
      repo_names = results
        .map { |pr| pr["repository_url"]&.split("/")&.last }
        .compact
        .uniq
      
      puts "Found #{repo_names.size} repositories where #{username} has commented on PRs"
      repo_names
    rescue Error => e
      puts "Warning: PR comment search failed - #{e.message}"
      []
    end

    # Search for issues where the user has commented
    def search_commented_issues(username, since: nil)
      date_filter = since ? " created:>=#{format_date_for_search(since)}" : ""
      query = "org:#{@organization} commenter:#{username} type:issue#{date_filter}"
      
      results = []
      page = 1
      
      loop do
        encoded_query = URI.encode_www_form_component(query)
        endpoint = "/search/issues?q=#{encoded_query}&page=#{page}&per_page=100"
        
        response = make_request(endpoint)
        data = JSON.parse(response.body)
        
        break if data["items"].nil? || data["items"].empty?
        
        results.concat(data["items"])
        
        break if results.size >= data["total_count"] || results.size >= 1000
        
        page += 1
        sleep(1) unless @disable_sleep
      end
      
      # Extract unique repository names
      repo_names = results
        .map { |issue| issue["repository_url"]&.split("/")&.last }
        .compact
        .uniq
      
      puts "Found #{repo_names.size} repositories where #{username} has commented on issues"
      repo_names
    rescue Error => e
      puts "Warning: Issue comment search failed - #{e.message}"
      []
    end

    # Fetch issues assigned to or created by a user
    def fetch_issues(repo_name, assignee: nil, creator: nil, state: "all", since: nil)
      params = { state: state }
      params[:assignee] = assignee if assignee
      params[:creator] = creator if creator
      params[:since] = since.iso8601 if since
      
      query_string = URI.encode_www_form(params)
      get_paginated("/repos/#{@organization}/#{repo_name}/issues?#{query_string}")
    end

    # Fetch comments made by a user on issues in a repository
    def fetch_issue_comments_by_user(repo_name, username, since: nil)
      all_comments = get_paginated("/repos/#{@organization}/#{repo_name}/issues/comments")
      comments = all_comments.select { |comment| comment["user"]["login"] == username }
      
      # Filter by date if specified
      if since
        since_time = since.is_a?(Date) ? since.to_time : since
        comments = comments.select do |comment|
          created_at = Time.parse(comment["created_at"])
          created_at >= since_time
        end
      end
      
      comments
    end

    # Fetch PR comments made by a user in a repository
    def fetch_pr_comments_by_user(repo_name, username, since: nil)
      all_comments = get_paginated("/repos/#{@organization}/#{repo_name}/pulls/comments")
      comments = all_comments.select { |comment| comment["user"]["login"] == username }
      
      # Filter by date if specified
      if since
        since_time = since.is_a?(Date) ? since.to_time : since
        comments = comments.select do |comment|
          created_at = Time.parse(comment["created_at"])
          created_at >= since_time
        end
      end
      
      comments
    end

    private

    def format_date_for_search(date)
      # Convert Date or Time to ISO8601 format (YYYY-MM-DD) for GitHub search
      date_obj = date.is_a?(Date) ? date : Date.parse(date.to_s)
      date_obj.strftime("%Y-%m-%d")
    end

    def get_paginated(endpoint, page: 1, per_page: 100)
      results = []
      
      loop do
        separator = endpoint.include?("?") ? "&" : "?"
        url = "#{endpoint}#{separator}page=#{page}&per_page=#{per_page}"
        
        response = make_request(url)
        data = JSON.parse(response.body)
        
        break if data.empty?
        
        results.concat(data)
        page += 1
        
        # Respect rate limits
        sleep(0.1) unless @disable_sleep
      end
      
      results
    end

    def make_request(endpoint)
      uri = URI("#{BASE_URL}#{endpoint}")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "token #{@token}"
      request["Accept"] = "application/vnd.github.v3+json"
      request["User-Agent"] = "IcMetrics/1.0"
      
      response = http.request(request)
      
      case response.code
      when "200"
        response
      when "404"
        raise Error, "Resource not found: #{endpoint}"
      when "403"
        raise Error, "Rate limit exceeded or insufficient permissions"
      when "401"
        raise Error, "Invalid GitHub token"
      else
        raise Error, "GitHub API error: #{response.code} - #{response.body}"
      end
    end
  end
end
