# frozen_string_literal: true

# Example usage script demonstrating the IC Metrics tool
# This script shows how to use the tool programmatically

require_relative 'lib/ic_metrics'

# Example 1: Collect data for a developer
def collect_example
  config = IcMetrics::Config.new
  collector = IcMetrics::DataCollector.new(config)

  # Collect data for the last 3 months
  since_date = Date.today - 90
  collector.collect_developer_data('developer-username', since: since_date)
end

# Example 2: Analyze collected data
def analyze_example
  config = IcMetrics::Config.new
  analyzer = IcMetrics::ContributionAnalyzer.new(config)

  analysis = analyzer.analyze_developer('developer-username')

  puts 'Analysis completed!'
  puts "Total commits: #{analysis[:summary]['total_commits']}"
  puts "Total PRs: #{analysis[:summary]['total_prs']}"
  puts "Recommendations: #{analysis[:recommendations].join(', ')}"
end

# Example 3: Direct GitHub API usage
def api_example
  config = IcMetrics::Config.new
  client = IcMetrics::GithubClient.new(config)

  # Get repositories
  repos = client.fetch_repositories
  puts "Found #{repos.size} repositories"

  # Get commits for a specific user in a specific repo
  commits = client.fetch_commits('repo-name', 'username')
  puts "Found #{commits.size} commits"
end

# Uncomment to run examples:
# collect_example
# analyze_example
# api_example
