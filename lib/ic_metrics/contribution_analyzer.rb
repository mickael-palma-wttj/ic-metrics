# frozen_string_literal: true

module IcMetrics
  # Analyzer to generate insights from collected contribution data
  class ContributionAnalyzer
    def initialize(config)
      @config = config
      @data_dir = config.data_directory
    end

    # Analyze contributions for a developer
    def analyze_developer(username)
      data_file = File.join(@data_dir, username, "contributions.json")
      
      unless File.exist?(data_file)
        raise Error, "No data found for developer: #{username}. Run data collection first."
      end
      
      data = JSON.parse(File.read(data_file))
      
      analysis = {
        developer: username,
        analyzed_at: Time.now.iso8601,
        period: extract_period(data),
        summary: data["summary"],
        detailed_analysis: perform_detailed_analysis(data),
        recommendations: generate_recommendations(data)
      }
      
      # Save analysis
      analysis_file = File.join(@data_dir, username, "analysis.json")
      File.write(analysis_file, JSON.pretty_generate(analysis))
      
      # Generate report
      generate_report(analysis)
      
      analysis
    end

    private

    def extract_period(data)
      all_dates = []
      
      data["repositories"].each do |repo_name, repo_data|
        repo_data["commits"].each { |commit| all_dates << commit["commit"]["author"]["date"] }
        repo_data["pull_requests"].each { |pr| all_dates << pr["created_at"] }
        repo_data["reviews"].each { |review| all_dates << review["submitted_at"] }
        repo_data["issues"].each { |issue| all_dates << issue["created_at"] }
        repo_data["pr_comments"]&.each { |comment| all_dates << comment["created_at"] }
        repo_data["issue_comments"]&.each { |comment| all_dates << comment["created_at"] }
      end
      
      return { from: nil, to: nil } if all_dates.empty?
      
      dates = all_dates.compact.map { |date| Time.parse(date) }.sort
      {
        from: dates.first.iso8601,
        to: dates.last.iso8601,
        duration_days: (dates.last - dates.first).to_i / (24 * 60 * 60)
      }
    end

    def perform_detailed_analysis(data)
      repositories = data["repositories"]
      
      {
        activity_by_repository: analyze_activity_by_repository(repositories),
        commit_patterns: analyze_commit_patterns(repositories),
        pr_patterns: analyze_pr_patterns(repositories),
        review_patterns: analyze_review_patterns(repositories),
        collaboration_metrics: analyze_collaboration(repositories),
        productivity_metrics: calculate_productivity_metrics(repositories)
      }
    end

    def analyze_activity_by_repository(repositories)
      repositories.map do |repo_name, repo_data|
        {
          repository: repo_name,
          commits: repo_data["commits"].size,
          pull_requests: repo_data["pull_requests"].size,
          reviews: repo_data["reviews"].size,
          issues: repo_data["issues"].size,
          pr_comments: (repo_data["pr_comments"] || []).size,
          issue_comments: (repo_data["issue_comments"] || []).size,
          total_activity: repo_data["commits"].size + repo_data["pull_requests"].size + 
                         repo_data["reviews"].size + repo_data["issues"].size +
                         (repo_data["pr_comments"] || []).size + (repo_data["issue_comments"] || []).size
        }
      end.sort_by { |repo| -repo[:total_activity] }
    end

    def analyze_commit_patterns(repositories)
      all_commits = repositories.values.flat_map { |repo| repo["commits"] }
      return {} if all_commits.empty?
      
      commit_dates = all_commits.map { |commit| Time.parse(commit["commit"]["author"]["date"]) }
      
      {
        total_commits: all_commits.size,
        avg_commits_per_day: calculate_avg_per_day(commit_dates),
        commit_frequency: analyze_frequency(commit_dates),
        most_active_hours: analyze_commit_hours(commit_dates),
        commit_message_analysis: analyze_commit_messages(all_commits)
      }
    end

    def analyze_pr_patterns(repositories)
      all_prs = repositories.values.flat_map { |repo| repo["pull_requests"] }
      return {} if all_prs.empty?
      
      {
        total_prs: all_prs.size,
        pr_states: all_prs.group_by { |pr| pr["state"] }.transform_values(&:count),
        avg_pr_size: calculate_avg_pr_size(all_prs),
        pr_merge_rate: calculate_merge_rate(all_prs),
        avg_time_to_merge: calculate_avg_time_to_merge(all_prs)
      }
    end

    def analyze_review_patterns(repositories)
      all_reviews = repositories.values.flat_map { |repo| repo["reviews"] }
      return {} if all_reviews.empty?
      
      {
        total_reviews: all_reviews.size,
        review_states: all_reviews.group_by { |review| review["state"] }.transform_values(&:count),
        avg_reviews_per_day: calculate_avg_per_day(all_reviews.map { |r| Time.parse(r["submitted_at"]) }),
        review_response_time: analyze_review_response_time(all_reviews)
      }
    end

    def analyze_collaboration(repositories)
      all_prs = repositories.values.flat_map { |repo| repo["pull_requests"] }
      all_reviews = repositories.values.flat_map { |repo| repo["reviews"] }
      
      collaborators = Set.new
      all_prs.each { |pr| collaborators.add(pr["user"]["login"]) }
      all_reviews.each { |review| collaborators.add(review["user"]["login"]) }
      
      {
        unique_collaborators: collaborators.size - 1, # Exclude the developer themselves
        repositories_contributed_to: repositories.count { |_, data| 
          data["commits"].any? || data["pull_requests"].any? || data["reviews"].any?
        },
        cross_repo_activity: repositories.count { |_, data| data["commits"].any? } > 1
      }
    end

    def calculate_productivity_metrics(repositories)
      all_commits = repositories.values.flat_map { |repo| repo["commits"] }
      all_prs = repositories.values.flat_map { |repo| repo["pull_requests"] }
      
      if all_commits.empty?
        return { weekly_commit_avg: 0, monthly_commit_avg: 0, pr_creation_rate: 0 }
      end
      
      commit_dates = all_commits.map { |commit| Time.parse(commit["commit"]["author"]["date"]) }
      first_date = commit_dates.min
      last_date = commit_dates.max
      
      weeks = [(last_date - first_date) / (7 * 24 * 60 * 60), 1].max
      months = [(last_date - first_date) / (30 * 24 * 60 * 60), 1].max
      
      {
        weekly_commit_avg: (all_commits.size / weeks).round(2),
        monthly_commit_avg: (all_commits.size / months).round(2),
        pr_creation_rate: (all_prs.size / months).round(2)
      }
    end

    def calculate_avg_per_day(dates)
      return 0 if dates.empty?
      
      first_date = dates.min
      last_date = dates.max
      days = [(last_date - first_date) / (24 * 60 * 60), 1].max
      
      (dates.size / days).round(2)
    end

    def analyze_frequency(dates)
      return {} if dates.empty?
      
      by_day = dates.group_by { |date| date.strftime("%A") }
      by_hour = dates.group_by { |date| date.hour }
      
      {
        by_day_of_week: by_day.transform_values(&:count),
        by_hour: by_hour.transform_values(&:count)
      }
    end

    def analyze_commit_hours(dates)
      return [] if dates.empty?
      
      hourly_counts = dates.group_by(&:hour).transform_values(&:count)
      hourly_counts.sort_by { |hour, count| -count }.first(3).map(&:first)
    end

    def analyze_commit_messages(commits)
      messages = commits.map { |commit| commit["commit"]["message"] }
      
      {
        avg_message_length: messages.map(&:length).sum / messages.size.to_f,
        conventional_commits: messages.count { |msg| msg.match?(/^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?:/) },
        conventional_commit_percentage: (messages.count { |msg| msg.match?(/^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?:/) } / messages.size.to_f * 100).round(2)
      }
    end

    def calculate_avg_pr_size(prs)
      sizes = prs.map { |pr| (pr["additions"] || 0) + (pr["deletions"] || 0) }.compact
      return 0 if sizes.empty?
      
      sizes.sum / sizes.size.to_f
    end

    def calculate_merge_rate(prs)
      merged = prs.count { |pr| pr["merged_at"] }
      return 0 if prs.empty?
      
      (merged / prs.size.to_f * 100).round(2)
    end

    def calculate_avg_time_to_merge(prs)
      merged_prs = prs.select { |pr| pr["merged_at"] }
      return 0 if merged_prs.empty?
      
      total_time = merged_prs.sum do |pr|
        created = Time.parse(pr["created_at"])
        merged = Time.parse(pr["merged_at"])
        (merged - created) / (24 * 60 * 60) # Convert to days
      end
      
      (total_time / merged_prs.size).round(2)
    end

    def analyze_review_response_time(reviews)
      # This would require PR creation dates to calculate properly
      # For now, return a placeholder
      { avg_response_time_hours: "N/A - requires PR creation data" }
    end

    def generate_recommendations(data)
      recommendations = []
      summary = data["summary"]
      
      # Commit frequency recommendations
      if summary["total_commits"] < 10
        recommendations << "Consider increasing commit frequency for better code tracking"
      end
      
      # PR recommendations
      if summary["total_prs"] == 0
        recommendations << "No pull requests found - consider using PRs for code review and collaboration"
      elsif summary["total_prs"] < summary["total_commits"] / 10
        recommendations << "Consider creating more pull requests to improve code review process"
      end
      
      # Review participation
      if summary["total_reviews"] < summary["total_prs"]
        recommendations << "Increase participation in code reviews to improve team collaboration"
      end
      
      # Issue engagement
      if summary["total_issues"] == 0
        recommendations << "Consider engaging more with issues for better project planning and bug tracking"
      end
      
      recommendations << "Great work on contributing to the codebase!" if recommendations.empty?
      
      recommendations
    end

    def generate_report(analysis)
      report_lines = []
      report_lines << "# Developer Contribution Analysis Report"
      report_lines << ""
      report_lines << "**Developer**: #{analysis[:developer]}"
      report_lines << "**Organization**: #{@config.organization}"
      report_lines << "**Analysis Date**: #{analysis[:analyzed_at]}"
      report_lines << ""
      
      if analysis[:period][:from]
        report_lines << "**Activity Period**: #{analysis[:period][:from]} to #{analysis[:period][:to]}"
        report_lines << "**Duration**: #{analysis[:period][:duration_days]} days"
        report_lines << ""
      end
      
      report_lines << "## Summary"
      summary = analysis[:summary]
      report_lines << "- **Total Commits**: #{summary['total_commits']}"
      report_lines << "- **Total Pull Requests**: #{summary['total_prs']}"
      report_lines << "- **Total Reviews**: #{summary['total_reviews']}"
      report_lines << "- **Total Issues**: #{summary['total_issues']}"
      report_lines << "- **Total PR Comments**: #{summary['total_pr_comments'] || 0}"
      report_lines << "- **Total Issue Comments**: #{summary['total_issue_comments'] || 0}"
      report_lines << ""
      
      report_lines << "## Activity by Repository"
      analysis[:detailed_analysis][:activity_by_repository].each do |repo|
        report_lines << "- **#{repo[:repository]}**: #{repo[:total_activity]} total activities"
      end
      report_lines << ""
      
      report_lines << "## Recommendations"
      analysis[:recommendations].each do |recommendation|
        report_lines << "- #{recommendation}"
      end
      
      report_content = report_lines.join("\n")
      report_file = File.join(@data_dir, analysis[:developer], "report.md")
      File.write(report_file, report_content)
      
      puts "Report generated: #{report_file}"
    end
  end
end
