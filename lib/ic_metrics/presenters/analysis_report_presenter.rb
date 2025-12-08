# frozen_string_literal: true

module IcMetrics
  module Presenters
    # Presenter for rendering contribution analysis reports
    class AnalysisReportPresenter
      def initialize(analysis, config)
        @analysis = analysis
        @config = config
      end

      def render
        [
          render_header,
          render_period,
          render_summary,
          render_activity_by_repository,
          render_recommendations
        ].compact.join("\n")
      end

      private

      def render_header
        [
          '# Developer Contribution Analysis Report',
          '',
          "**Developer**: #{@analysis[:developer]}",
          "**Organization**: #{@config.organization}",
          "**Analysis Date**: #{@analysis[:analyzed_at]}",
          ''
        ].join("\n")
      end

      def render_period
        return unless @analysis[:period][:from]

        [
          "**Activity Period**: #{@analysis[:period][:from]} to #{@analysis[:period][:to]}",
          "**Duration**: #{@analysis[:period][:duration_days]} days",
          ''
        ].join("\n")
      end

      def render_summary
        summary = @analysis[:summary]
        [
          '## Summary',
          "- **Total Commits**: #{summary['total_commits']}",
          "- **Total Pull Requests**: #{summary['total_prs']}",
          "- **Total Reviews**: #{summary['total_reviews']}",
          "- **Total Issues**: #{summary['total_issues']}",
          "- **Total PR Comments**: #{summary['total_pr_comments'] || 0}",
          "- **Total Issue Comments**: #{summary['total_issue_comments'] || 0}",
          ''
        ].join("\n")
      end

      def render_activity_by_repository
        lines = ['## Activity by Repository']
        @analysis[:detailed_analysis][:activity_by_repository].each do |repo|
          lines << "- **#{repo[:repository]}**: #{repo[:total_activity]} total activities"
        end
        lines << ''
        lines.join("\n")
      end

      def render_recommendations
        lines = ['## Recommendations']
        @analysis[:recommendations].each do |recommendation|
          lines << "- #{recommendation}"
        end
        lines.join("\n")
      end
    end
  end
end
