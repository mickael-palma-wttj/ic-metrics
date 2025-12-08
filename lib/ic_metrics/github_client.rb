# frozen_string_literal: true

module IcMetrics
  # GitHub API client for fetching contribution data
  class GithubClient
    PAGINATION_PER_PAGE = 100
    SECONDS_PER_DAY = 86_400 # 24 * 60 * 60

    attr_reader :organization

    def initialize(config)
      @token = config.github_token
      @organization = config.organization
      @http_client = Services::HttpClient.new(@token)
      @rate_limiter = Services::RateLimiter.standard
      @search_rate_limiter = Services::RateLimiter.search
      @paginated_request = Services::PaginatedRequest.new(@http_client, @rate_limiter)
      @query_builder = Utils::GithubQueryBuilder.new(@organization)
    end

    # Make a request and return parsed JSON (public for service use)
    # @param endpoint [String] API endpoint
    # @return [Hash] Parsed JSON response
    def request(endpoint)
      response = @http_client.get(endpoint)
      JSON.parse(response.body)
    end

    # Fetch all repositories for the organization
    def fetch_repositories
      get_paginated("/orgs/#{@organization}/repos")
    end

    # Fetch repositories where a specific user has contributed
    def fetch_user_repositories(username, since: nil)
      repository_aggregator.aggregate_user_repositories(username, since)
    end

    # Search repositories using GitHub search API
    def search_repositories(query)
      results = []
      page = 1
      max_results = 1000

      loop do
        data = fetch_search_page(query, page)
        break if data['items'].nil? || data['items'].empty?

        results.concat(data['items'])
        break if results.size >= data['total_count'] || results.size >= max_results

        page += 1
        @search_rate_limiter.wait
      end

      results
    rescue Error => e
      handle_search_error(e)
    end

    # Get repositories where user has been active (alternative approach using events API)
    def fetch_user_activity_repositories(username)
      puts 'Fetching user activity to find additional repositories...'

      # Get user's public events to find repositories they've interacted with
      events = get_paginated("/users/#{username}/events/public")

      repo_names = events
                   .select { |event| event['repo'] && event['repo']['name'].start_with?("#{@organization}/") }
                   .map { |event| event['repo']['name'].split('/').last }
                   .uniq

      puts "Found #{repo_names.size} additional repositories from user activity"

      # Fetch repository details for each found repo
      repositories = []
      repo_names.each do |repo_name|
        repo_data = request("/repos/#{@organization}/#{repo_name}")
        repositories << repo_data
      rescue Error => e
        puts "Warning: Could not fetch details for repository #{repo_name}: #{e.message}"
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
      commits = get_paginated("/repos/#{@organization}/#{repo_name}/commits?#{query_string}")

      # Enrich commits with detailed stats (additions, deletions)
      commits.each do |commit|
        commit_detail = request("/repos/#{@organization}/#{repo_name}/commits/#{commit['sha']}")
        commit['stats'] = commit_detail['stats'] if commit_detail && commit_detail['stats']
      rescue StandardError
        # If we can't fetch detailed stats, just use empty stats
        commit['stats'] ||= { 'additions' => 0, 'deletions' => 0, 'total' => 0 }
      end

      commits
    end

    # Fetch pull requests for a repository
    def fetch_pull_requests(repo_name, author: nil, state: 'all', since: nil)
      params = { state: state }
      query_string = URI.encode_www_form(params)

      prs = get_paginated("/repos/#{@organization}/#{repo_name}/pulls?#{query_string}")

      # Filter by author if specified
      prs = prs.select { |pr| pr['user']['login'] == author } if author

      # Filter by date if specified
      if since
        since_time = since.is_a?(Date) ? since.to_time : since
        prs = prs.select do |pr|
          created_at = Time.parse(pr['created_at'])
          created_at >= since_time
        end
      end

      prs
    end

    # Fetch reviews for a specific pull request
    def fetch_reviews(repo_name, pr_number)
      reviews = get_paginated("/repos/#{@organization}/#{repo_name}/pulls/#{pr_number}/reviews")
      comments = get_paginated("/repos/#{@organization}/#{repo_name}/pulls/#{pr_number}/comments")

      Models::ReviewEnricher.new(reviews, comments).enrich
    end

    # Fetch review comments for a specific pull request
    def fetch_review_comments(repo_name, pr_number)
      get_paginated("/repos/#{@organization}/#{repo_name}/pulls/#{pr_number}/comments")
    end

    # Search for pull requests where the user was a reviewer
    def search_reviewed_prs(username, since: nil)
      query = @query_builder.for_user_activity(username, since: since, type: 'pr', filter: 'reviewed-by')
      results = search_service.search_paged(query)
      extract_repository_names(results, username, 'reviewed PRs')
    end

    # Search for pull requests where the user has commented
    def search_commented_prs(username, since: nil)
      query = @query_builder.for_user_activity(username, since: since, type: 'pr', filter: 'commenter')
      results = search_service.search_paged(query)
      extract_repository_names(results, username, 'commented on PRs')
    end

    # Search for issues where the user has commented
    def search_commented_issues(username, since: nil)
      query = @query_builder.for_user_activity(username, since: since, type: 'issue', filter: 'commenter')
      results = search_service.search_paged(query)
      extract_repository_names(results, username, 'commented on issues')
    end

    # Fetch issues assigned to or created by a user
    def fetch_issues(repo_name, assignee: nil, creator: nil, state: 'all', since: nil)
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

    def repository_aggregator
      @repository_aggregator ||= Services::RepositoryAggregator.new(self, @query_builder)
    end

    def fetch_search_page(query, page)
      encoded_query = URI.encode_www_form_component(query)
      endpoint = "/search/repositories?q=#{encoded_query}&page=#{page}&per_page=100"
      request(endpoint)
    end

    def handle_search_error(error)
      puts "Warning: Repository search failed - #{error.message}"
      puts 'Falling back to fetching all organization repositories'
      fetch_repositories
    end

    def extract_repository_names(results, username, context)
      repo_names = results
                   .filter_map { |item| item['repository_url']&.split('/')&.last }
                   .uniq

      puts "Found #{repo_names.size} repositories where #{username} has #{context}"
      repo_names
    rescue Error => e
      puts "Warning: Search failed for #{context} - #{e.message}"
      []
    end

    def filter_comments_by_user_and_date(comments, username, since)
      comments
        .select { |comment| comment['user']['login'] == username }
        .select { |comment| Utils::DateFilter.within_range?(comment['created_at'], since) }
    end

    def get_paginated(endpoint, per_page: PAGINATION_PER_PAGE)
      @paginated_request.fetch_all(endpoint, per_page: per_page)
    end
  end
end
