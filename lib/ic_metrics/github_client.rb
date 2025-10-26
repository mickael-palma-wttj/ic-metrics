# frozen_string_literal: true

module IcMetrics
  # GitHub API client for fetching contribution data
  class GithubClient
    BASE_URL = "https://api.github.com"
    PAGINATION_PER_PAGE = 100
    RATE_LIMIT_DELAY = 0.1
    SEARCH_RATE_LIMIT_DELAY = 1
    SECONDS_PER_DAY = 86_400 # 24 * 60 * 60
    
    def initialize(config)
      @token = config.github_token
      @organization = config.organization
      @disable_sleep = ENV["DISABLE_SLEEP"] == "true"
    end

    # Make a request and return parsed JSON (public for service use)
    # @param endpoint [String] API endpoint
    # @return [Hash] Parsed JSON response
    def request(endpoint)
      response = make_request(endpoint)
      JSON.parse(response.body)
    end

    # Fetch all repositories for the organization
    def fetch_repositories
      get_paginated("/orgs/#{@organization}/repos")
    end

    # Fetch repositories where a specific user has contributed
    def fetch_user_repositories(username, since: nil)
      puts "Searching for repositories with contributions from #{username}..."
      
      date_filter = build_date_filter(since)
      
      # Collect all repository sources
      repo_collections = [
        search_author_repositories(username, date_filter),
        search_pr_repositories(username, date_filter),
        search_issue_repositories(username, date_filter),
        fetch_reviewed_repositories(username, since),
        fetch_commented_pr_repositories(username, since),
        fetch_commented_issue_repositories(username, since),
        fetch_user_activity_repositories(username)
      ]
      
      # Combine and deduplicate
      all_repos = repo_collections.flatten.uniq { |repo| repo["id"] }
      
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
        sleep(SEARCH_RATE_LIMIT_DELAY) unless @disable_sleep
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
      query = build_search_query(username, since, type: "pr", filter: "reviewed-by")
      results = search_service.search_paged(query)
      extract_repository_names(results, username, "reviewed PRs")
    end

    # Search for pull requests where the user has commented
    def search_commented_prs(username, since: nil)
      query = build_search_query(username, since, type: "pr", filter: "commenter")
      results = search_service.search_paged(query)
      extract_repository_names(results, username, "commented on PRs")
    end

    # Search for issues where the user has commented
    def search_commented_issues(username, since: nil)
      query = build_search_query(username, since, type: "issue", filter: "commenter")
      results = search_service.search_paged(query)
      extract_repository_names(results, username, "commented on issues")
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
      filter_comments_by_user_and_date(all_comments, username, since)
    end

    # Fetch PR comments made by a user in a repository
    def fetch_pr_comments_by_user(repo_name, username, since: nil)
      all_comments = get_paginated("/repos/#{@organization}/#{repo_name}/pulls/comments")
      filter_comments_by_user_and_date(all_comments, username, since)
    end

    private

    def search_service
      @search_service ||= Services::GithubSearchService.new(self)
    end

    def build_date_filter(since)
      since ? " created:>=#{Utils::DateFilter.format_for_search(since)}" : ""
    end

    def search_author_repositories(username, date_filter)
      search_repositories("org:#{@organization} author:#{username}#{date_filter}")
    end

    def search_pr_repositories(username, date_filter)
      search_repositories("org:#{@organization} author:#{username} type:pr#{date_filter}")
    end

    def search_issue_repositories(username, date_filter)
      search_repositories("org:#{@organization} author:#{username} type:issue#{date_filter}")
    end

    def fetch_reviewed_repositories(username, since)
      repo_names = search_reviewed_prs(username, since: since)
      fetch_repository_details(repo_names)
    end

    def fetch_commented_pr_repositories(username, since)
      repo_names = search_commented_prs(username, since: since)
      fetch_repository_details(repo_names)
    end

    def fetch_commented_issue_repositories(username, since)
      repo_names = search_commented_issues(username, since: since)
      fetch_repository_details(repo_names)
    end

    def build_search_query(username, since, type:, filter:)
      query_parts = ["org:#{@organization}", "#{filter}:#{username}", "type:#{type}"]
      query_parts << "created:>=#{Utils::DateFilter.format_for_search(since)}" if since
      query_parts.join(" ")
    end

    def extract_repository_names(results, username, context)
      repo_names = results
        .map { |item| item.dig("repository_url")&.split("/")&.last }
        .compact
        .uniq

      puts "Found #{repo_names.size} repositories where #{username} has #{context}"
      repo_names
    rescue Error => e
      puts "Warning: Search failed for #{context} - #{e.message}"
      []
    end

    def fetch_repository_details(repo_names)
      repo_names.uniq.map do |repo_name|
        request("/repos/#{@organization}/#{repo_name}")
      rescue Error => e
        puts "Warning: Could not fetch details for repository #{repo_name}: #{e.message}"
        nil
      end.compact
    end

    def filter_comments_by_user_and_date(comments, username, since)
      comments
        .select { |comment| comment["user"]["login"] == username }
        .select { |comment| Utils::DateFilter.within_range?(comment["created_at"], since) }
    end

    def get_paginated(endpoint, page: 1, per_page: PAGINATION_PER_PAGE)
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
        sleep(RATE_LIMIT_DELAY) unless @disable_sleep
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
        raise Errors::ResourceNotFoundError.new(
          "Resource not found",
          status_code: 404,
          endpoint: endpoint
        )
      when "403"
        raise Errors::RateLimitError.new(
          "Rate limit exceeded or insufficient permissions",
          status_code: 403,
          endpoint: endpoint
        )
      when "401"
        raise Errors::AuthenticationError.new(
          "Invalid GitHub token",
          status_code: 401,
          endpoint: endpoint
        )
      else
        raise Errors::ApiError.new(
          "GitHub API error: #{response.body}",
          status_code: response.code.to_i,
          endpoint: endpoint
        )
      end
    end
  end
end
