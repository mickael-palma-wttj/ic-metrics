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
      save_analysis_file(username, analysis)
      generate_report(username, analysis)
    end

    def save_analysis_file(username, analysis)
      analysis_file = File.join(@data_dir, username, 'analysis.json')
      File.write(analysis_file, JSON.pretty_generate(analysis))
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
      repositories.flat_map do |_name, repo_data|
        extract_dates_from_repository(repo_data)
      end
    end

    def extract_dates_from_repository(repo_data)
      [
        extract_commit_dates(repo_data['commits']),
        extract_created_dates(repo_data['pull_requests']),
        extract_submitted_dates(repo_data['reviews']),
        extract_created_dates(repo_data['issues']),
        extract_created_dates(repo_data['pr_comments'] || []),
        extract_created_dates(repo_data['issue_comments'] || [])
      ].flatten
    end

    def extract_commit_dates(commits)
      commits.map { |c| c.dig('commit', 'author', 'date') }
    end

    def extract_created_dates(items)
      items.map { |item| item['created_at'] }
    end

    def extract_submitted_dates(reviews)
      reviews.map { |r| r['submitted_at'] }
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
      summary = data['summary']
      recommendations = [
        commit_recommendation(summary),
        pr_recommendation(summary),
        review_recommendation(summary),
        issue_recommendation(summary)
      ].compact

      recommendations.empty? ? default_recommendation : recommendations
    end

    def commit_recommendation(summary)
      return unless summary['total_commits'] < 10

      'Consider increasing commit frequency for better code tracking'
    end

    def pr_recommendation(summary)
      if summary['total_prs'].zero?
        return 'No pull requests found - consider using PRs for code review and collaboration'
      end
      return unless summary['total_prs'] < summary['total_commits'] / 10

      'Consider creating more pull requests to improve code review process'
    end

    def review_recommendation(summary)
      return unless summary['total_reviews'] < summary['total_prs']

      'Increase participation in code reviews to improve team collaboration'
    end

    def issue_recommendation(summary)
      return unless summary['total_issues'].zero?

      'Consider engaging more with issues for better project planning and bug tracking'
    end

    def default_recommendation
      ['Great work on contributing to the codebase!']
    end

    def generate_report(username, analysis)
      presenter = Presenters::AnalysisReportPresenter.new(analysis, @config)
      report_file = File.join(@data_dir, username, 'report.md')
      File.write(report_file, presenter.render)
      puts "Report generated: #{report_file}"
    end
  end
end
