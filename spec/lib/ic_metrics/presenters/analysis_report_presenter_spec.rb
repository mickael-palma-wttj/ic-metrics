# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::Presenters::AnalysisReportPresenter do
  subject(:presenter) { described_class.new(analysis, config) }

  let(:config) { instance_double(IcMetrics::Config, organization: 'TestOrg') }
  let(:analysis) do
    {
      developer: 'testuser',
      analyzed_at: '2025-12-08T10:00:00Z',
      period: {
        from: '2025-01-01T00:00:00Z',
        to: '2025-12-08T00:00:00Z',
        duration_days: 341
      },
      summary: {
        'total_commits' => 120,
        'total_prs' => 25,
        'total_reviews' => 30,
        'total_issues' => 10,
        'total_pr_comments' => 50,
        'total_issue_comments' => 15
      },
      detailed_analysis: {
        activity_by_repository: [
          { repository: 'repo1', total_activity: 150 },
          { repository: 'repo2', total_activity: 100 }
        ]
      },
      recommendations: [
        'Great work on contributing to the codebase!',
        'Consider documenting complex features'
      ]
    }
  end

  describe '#render' do
    it 'generates complete markdown report' do
      # Exercise
      result = presenter.render

      # Verify
      aggregate_failures do
        expect(result).to be_a(String)
        expect(result).to include('# Developer Contribution Analysis Report')
        expect(result).to include('testuser')
        expect(result).to include('TestOrg')
        expect(result).to include('2025-12-08T10:00:00Z')
      end
    end

    it 'includes period information' do
      # Exercise
      result = presenter.render

      # Verify
      aggregate_failures do
        expect(result).to include('Activity Period')
        expect(result).to include('2025-01-01T00:00:00Z')
        expect(result).to include('2025-12-08T00:00:00Z')
        expect(result).to include('341 days')
      end
    end

    it 'includes summary statistics' do
      # Exercise
      result = presenter.render

      # Verify
      aggregate_failures do
        expect(result).to include('## Summary')
        expect(result).to include('Total Commits**: 120')
        expect(result).to include('Total Pull Requests**: 25')
        expect(result).to include('Total Reviews**: 30')
        expect(result).to include('Total Issues**: 10')
        expect(result).to include('Total PR Comments**: 50')
        expect(result).to include('Total Issue Comments**: 15')
      end
    end

    it 'includes activity by repository' do
      # Exercise
      result = presenter.render

      # Verify
      aggregate_failures do
        expect(result).to include('## Activity by Repository')
        expect(result).to include('repo1**: 150 total activities')
        expect(result).to include('repo2**: 100 total activities')
      end
    end

    it 'includes recommendations' do
      # Exercise
      result = presenter.render

      # Verify
      aggregate_failures do
        expect(result).to include('## Recommendations')
        expect(result).to include('Great work on contributing')
        expect(result).to include('Consider documenting complex features')
      end
    end

    context 'when period information is missing' do
      let(:analysis) do
        {
          developer: 'testuser',
          analyzed_at: '2025-12-08T10:00:00Z',
          period: { from: nil, to: nil },
          summary: {
            'total_commits' => 10,
            'total_prs' => 2,
            'total_reviews' => 3,
            'total_issues' => 1,
            'total_pr_comments' => 5,
            'total_issue_comments' => 2
          },
          detailed_analysis: {
            activity_by_repository: []
          },
          recommendations: ['Great work!']
        }
      end

      it 'does not include period section' do
        # Exercise
        result = presenter.render

        # Verify
        expect(result).not_to include('Activity Period')
      end

      it 'still includes other sections' do
        # Exercise
        result = presenter.render

        # Verify
        aggregate_failures do
          expect(result).to include('# Developer Contribution Analysis Report')
          expect(result).to include('## Summary')
          expect(result).to include('## Activity by Repository')
          expect(result).to include('## Recommendations')
        end
      end
    end

    context 'when summary values are missing' do
      let(:analysis) do
        {
          developer: 'testuser',
          analyzed_at: '2025-12-08T10:00:00Z',
          period: { from: nil, to: nil },
          summary: {
            'total_commits' => 10,
            'total_prs' => 2,
            'total_reviews' => 3,
            'total_issues' => 1
          },
          detailed_analysis: {
            activity_by_repository: []
          },
          recommendations: []
        }
      end

      it 'defaults missing comment counts to 0' do
        # Exercise
        result = presenter.render

        # Verify
        aggregate_failures do
          expect(result).to include('Total PR Comments**: 0')
          expect(result).to include('Total Issue Comments**: 0')
        end
      end
    end
  end

  describe 'private methods' do
    describe '#render_header' do
      it 'formats header correctly' do
        # Exercise
        result = presenter.send(:render_header)

        # Verify
        aggregate_failures do
          expect(result).to start_with('# Developer Contribution Analysis Report')
          expect(result).to include('**Developer**: testuser')
          expect(result).to include('**Organization**: TestOrg')
          expect(result).to include('**Analysis Date**: 2025-12-08T10:00:00Z')
        end
      end
    end

    describe '#render_summary' do
      it 'formats summary section correctly' do
        # Exercise
        result = presenter.send(:render_summary)

        # Verify
        aggregate_failures do
          expect(result).to include('## Summary')
          expect(result).to include('- **Total')
          expect(result.scan('**Total').length).to eq(6)
        end
      end
    end

    describe '#render_recommendations' do
      it 'formats recommendations as bullet list' do
        # Exercise
        result = presenter.send(:render_recommendations)

        # Verify
        aggregate_failures do
          expect(result).to include('## Recommendations')
          expect(result).to include('- Great work on contributing')
          expect(result).to include('- Consider documenting')
        end
      end
    end
  end
end
