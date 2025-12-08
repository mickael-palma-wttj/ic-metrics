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
      data = load_contribution_data(username)

      {
        developer: username,
        analyzed_at: Time.now.iso8601,
        period: extract_period(data),
        summary: data['summary'],
        detailed_analysis: perform_detailed_analysis(data),
        recommendations: generate_recommendations(data)
      }.tap do |analysis|
        save_and_report(username, analysis)
      end
    end

    private

    def load_contribution_data(username)
      data_file = File.join(@data_dir, username, 'contributions.json')

      unless File.exist?(data_file)
        raise Errors::DataNotFoundError, "No data found for developer: #{username}. Run data collection first."
      end

      JSON.parse(File.read(data_file))
    end

    def save_and_report(username, analysis)
      analysis_file = File.join(@data_dir, username, 'analysis.json')
      File.write(analysis_file, JSON.pretty_generate(analysis))
      generate_report(analysis)
    end

    def extract_period(data)
      all_dates = collect_all_dates(data['repositories'])

      return { from: nil, to: nil } if all_dates.empty?

      sorted_dates = all_dates.compact.map { |date| Time.parse(date) }.sort
      {
        from: sorted_dates.first.iso8601,
        to: sorted_dates.last.iso8601,
        duration_days: calculate_duration_days(sorted_dates)
      }
    end

    def collect_all_dates(repositories)
      [].tap do |dates|
        repositories.each_value do |repo_data|
          dates.concat(repo_data['commits'].map { |c| c.dig('commit', 'author', 'date') })
          dates.concat(repo_data['pull_requests'].map { |pr| pr['created_at'] })
          dates.concat(repo_data['reviews'].map { |r| r['submitted_at'] })
          dates.concat(repo_data['issues'].map { |i| i['created_at'] })
          dates.concat((repo_data['pr_comments'] || []).map { |c| c['created_at'] })
          dates.concat((repo_data['issue_comments'] || []).map { |c| c['created_at'] })
        end
      end
    end

    def calculate_duration_days(sorted_dates)
      ((sorted_dates.last - sorted_dates.first) / (24 * 60 * 60)).to_i
    end

    def perform_detailed_analysis(data)
      repositories = data['repositories']

      {
        activity_by_repository: Analyzers::ActivityAnalyzer.new(repositories).analyze,
        commit_patterns: Analyzers::CommitAnalyzer.new(repositories).analyze,
        pr_patterns: Analyzers::PrAnalyzer.new(repositories).analyze,
        review_patterns: Analyzers::ReviewAnalyzer.new(repositories).analyze,
        collaboration_metrics: Analyzers::CollaborationAnalyzer.new(repositories).analyze,
        productivity_metrics: Analyzers::ProductivityAnalyzer.new(repositories).analyze
      }
    end

    def generate_recommendations(data)
      recommendations = []
      summary = data['summary']

      # Commit frequency recommendations
      if summary['total_commits'] < 10
        recommendations << 'Consider increasing commit frequency for better code tracking'
      end

      # PR recommendations
      if summary['total_prs'].zero?
        recommendations << 'No pull requests found - consider using PRs for code review and collaboration'
      elsif summary['total_prs'] < summary['total_commits'] / 10
        recommendations << 'Consider creating more pull requests to improve code review process'
      end

      # Review participation
      if summary['total_reviews'] < summary['total_prs']
        recommendations << 'Increase participation in code reviews to improve team collaboration'
      end

      # Issue engagement
      if summary['total_issues'].zero?
        recommendations << 'Consider engaging more with issues for better project planning and bug tracking'
      end

      recommendations << 'Great work on contributing to the codebase!' if recommendations.empty?

      recommendations
    end

    def generate_report(analysis)
      report_lines = []
      report_lines << '# Developer Contribution Analysis Report'
      report_lines << ''
      report_lines << "**Developer**: #{analysis[:developer]}"
      report_lines << "**Organization**: #{@config.organization}"
      report_lines << "**Analysis Date**: #{analysis[:analyzed_at]}"
      report_lines << ''

      if analysis[:period][:from]
        report_lines << "**Activity Period**: #{analysis[:period][:from]} to #{analysis[:period][:to]}"
        report_lines << "**Duration**: #{analysis[:period][:duration_days]} days"
        report_lines << ''
      end

      report_lines << '## Summary'
      summary = analysis[:summary]
      report_lines << "- **Total Commits**: #{summary['total_commits']}"
      report_lines << "- **Total Pull Requests**: #{summary['total_prs']}"
      report_lines << "- **Total Reviews**: #{summary['total_reviews']}"
      report_lines << "- **Total Issues**: #{summary['total_issues']}"
      report_lines << "- **Total PR Comments**: #{summary['total_pr_comments'] || 0}"
      report_lines << "- **Total Issue Comments**: #{summary['total_issue_comments'] || 0}"
      report_lines << ''

      report_lines << '## Activity by Repository'
      analysis[:detailed_analysis][:activity_by_repository].each do |repo|
        report_lines << "- **#{repo[:repository]}**: #{repo[:total_activity]} total activities"
      end
      report_lines << ''

      report_lines << '## Recommendations'
      analysis[:recommendations].each do |recommendation|
        report_lines << "- #{recommendation}"
      end

      report_content = report_lines.join("\n")
      report_file = File.join(@data_dir, analysis[:developer], 'report.md')
      File.write(report_file, report_content)

      puts "Report generated: #{report_file}"
    end
  end
end
