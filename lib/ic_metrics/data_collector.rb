# frozen_string_literal: true

module IcMetrics
  # Data collector to fetch and store developer contribution data
  class DataCollector
    DEFAULT_MAX_PARALLEL_REQUESTS = 4

    def initialize(config)
      @config = config
      @client = GithubClient.new(config)
      @data_dir = config.data_directory
      @max_workers = (ENV["MAX_PARALLEL_WORKERS"] || DEFAULT_MAX_PARALLEL_REQUESTS).to_i
      @thread_pool = Concurrent::FixedThreadPool.new(@max_workers)
    end

    # Collect all contribution data for a developer
    def collect_developer_data(username, since: nil)
      puts "Collecting data for developer: #{username}"
      
      developer_dir = ensure_developer_directory(username)
      repositories = fetch_repositories_for_user(username, since)
      
      return create_empty_data_structure(username) if repositories.empty?
      
      puts "Found #{repositories.size} repositories with contributions from #{username}"
      
      build_contribution_data(username, repositories, since).tap do |data|
        save_data(developer_dir, "contributions.json", data)
        print_summary(data[:summary])
      end
    end

    private

    def ensure_developer_directory(username)
      File.join(@data_dir, username).tap do |dir|
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      end
    end

    def fetch_repositories_for_user(username, since)
      puts "Finding repositories where #{username} has contributed..."
      @client.fetch_user_repositories(username, since: since).tap do |repos|
        warn_if_no_repositories(username) if repos.empty?
      end
    end

    def warn_if_no_repositories(username)
      puts "No repositories found with contributions from #{username}"
      puts "This could mean:"
      puts "  - The user hasn't contributed to any repositories in #{@config.organization}"
      puts "  - The user's contributions are in private repositories you don't have access to"
      puts "  - The username is incorrect"
    end

    def build_contribution_data(username, repositories, since)
      {
        developer: username,
        organization: @config.organization,
        collected_at: Time.now.iso8601,
        repositories: collect_all_repository_data(repositories, username, since),
        summary: initialize_summary
      }.tap { |data| calculate_summary_totals(data) }
    end

    def collect_all_repository_data(repositories, username, since)
      puts "\nStarting data collection for #{repositories.size} repositories..."
      
      repo_data = {}
      
      repositories.each_with_index do |repo, index|
        repo_name = repo["name"]
        current = index + 1
        total = repositories.size
        
        puts "\n🔄 [#{current}/#{total}] Processing: #{repo_name}"
        
        begin
          data = collect_repository_data(repo_name, username, since)
          repo_data[repo_name] = data
          
          summary = summarize_repo_data(data)
          puts "✅ [#{current}/#{total}] Completed: #{repo_name} - #{summary}"
        rescue StandardError => e
          puts "❌ [#{current}/#{total}] Error: #{repo_name} - #{e.message}"
        end
      end
      
      puts "\n✨ All repositories processed!\n"
      
      repo_data
    end
    
    def summarize_repo_data(data)
      parts = []
      parts << "#{data[:commits].size} commits" if data[:commits].any?
      parts << "#{data[:pull_requests].size} PRs" if data[:pull_requests].any?
      parts << "#{data[:reviews].size} reviews" if data[:reviews].any?
      parts << "#{data[:issues].size} issues" if data[:issues].any?
      parts << "#{data[:pr_comments].size} PR comments" if data[:pr_comments].any?
      parts << "#{data[:issue_comments].size} issue comments" if data[:issue_comments].any?
      parts.empty? ? "no activity" : parts.join(", ")
    end
    


    def initialize_summary
      {
        total_commits: 0,
        total_prs: 0,
        total_reviews: 0,
        total_issues: 0,
        total_pr_comments: 0,
        total_issue_comments: 0
      }
    end

    def calculate_summary_totals(data)
      data[:repositories].each_value do |repo_data|
        data[:summary][:total_commits] += repo_data[:commits].size
        data[:summary][:total_prs] += repo_data[:pull_requests].size
        data[:summary][:total_reviews] += repo_data[:reviews].size
        data[:summary][:total_issues] += repo_data[:issues].size
        data[:summary][:total_pr_comments] += repo_data[:pr_comments].size
        data[:summary][:total_issue_comments] += repo_data[:issue_comments].size
      end
    end

    def print_summary(summary)
      puts "Data collection completed!"
      puts "Summary:"
      puts "  - Total commits: #{summary[:total_commits]}"
      puts "  - Total PRs: #{summary[:total_prs]}"
      puts "  - Total reviews: #{summary[:total_reviews]}"
      puts "  - Total issues: #{summary[:total_issues]}"
      puts "  - Total PR comments: #{summary[:total_pr_comments]}"
      puts "  - Total issue comments: #{summary[:total_issue_comments]}"
    end

    def collect_repository_data(repo_name, username, since)
      repository = Models::RepositoryData.new(
        repo_name: repo_name,
        username: username,
        client: @client,
        since: since,
        quiet: false
      )
      repository.collect
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
