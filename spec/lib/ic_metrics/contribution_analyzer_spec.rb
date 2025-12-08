# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::ContributionAnalyzer do
  subject(:analyzer) { described_class.new(config) }

  let(:config) { instance_double(IcMetrics::Config, data_directory: data_dir, organization: 'TestOrg') }
  let(:data_dir) { '/tmp/test_data' }
  let(:username) { 'testuser' }
  let(:contributions_file) { File.join(data_dir, username, 'contributions.json') }

  describe '#analyze_developer' do
    let(:contribution_data) do
      {
        'summary' => {
          'total_commits' => 50,
          'total_prs' => 10,
          'total_reviews' => 8,
          'total_issues' => 5,
          'total_pr_comments' => 15,
          'total_issue_comments' => 7
        },
        'repositories' => {
          'repo1' => {
            'commits' => [
              { 'commit' => { 'author' => { 'date' => '2025-01-15T10:00:00Z' } } }
            ],
            'pull_requests' => [{ 'created_at' => '2025-01-16T10:00:00Z' }],
            'reviews' => [{ 'submitted_at' => '2025-01-17T10:00:00Z' }],
            'issues' => [{ 'created_at' => '2025-01-18T10:00:00Z' }],
            'pr_comments' => [{ 'created_at' => '2025-01-19T10:00:00Z' }],
            'issue_comments' => [{ 'created_at' => '2025-01-20T10:00:00Z' }]
          }
        }
      }
    end

    before do
      FileUtils.mkdir_p(File.join(data_dir, username))
      File.write(contributions_file, JSON.generate(contribution_data))

      allow(IcMetrics::Analyzers::ActivityAnalyzer).to receive(:new).and_return(
        instance_double(IcMetrics::Analyzers::ActivityAnalyzer, analyze: [])
      )
      allow(IcMetrics::Analyzers::CommitAnalyzer).to receive(:new).and_return(
        instance_double(IcMetrics::Analyzers::CommitAnalyzer, analyze: {})
      )
      allow(IcMetrics::Analyzers::PrAnalyzer).to receive(:new).and_return(
        instance_double(IcMetrics::Analyzers::PrAnalyzer, analyze: {})
      )
      allow(IcMetrics::Analyzers::ReviewAnalyzer).to receive(:new).and_return(
        instance_double(IcMetrics::Analyzers::ReviewAnalyzer, analyze: {})
      )
      allow(IcMetrics::Analyzers::CollaborationAnalyzer).to receive(:new).and_return(
        instance_double(IcMetrics::Analyzers::CollaborationAnalyzer, analyze: {})
      )
      allow(IcMetrics::Analyzers::ProductivityAnalyzer).to receive(:new).and_return(
        instance_double(IcMetrics::Analyzers::ProductivityAnalyzer, analyze: {})
      )
      allow(IcMetrics::Presenters::AnalysisReportPresenter).to receive(:new).and_return(
        instance_double(IcMetrics::Presenters::AnalysisReportPresenter, render: 'Report content')
      )
      allow(File).to receive(:write).and_call_original
      allow($stdout).to receive(:puts)
    end

    after do
      FileUtils.rm_rf(File.join(data_dir, username))
    end

    context 'when contribution data exists' do
      it 'returns complete analysis hash' do
        # Exercise
        result = analyzer.analyze_developer(username)

        # Verify
        aggregate_failures do
          expect(result[:developer]).to eq(username)
          expect(result[:analyzed_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
          expect(result[:summary]).to eq(contribution_data['summary'])
          expect(result[:detailed_analysis]).to be_a(Hash)
          expect(result[:recommendations]).to be_an(Array)
          expect(result[:period]).to be_a(Hash)
        end
      end

      it 'saves analysis file' do
        # Exercise
        analyzer.analyze_developer(username)

        # Verify
        analysis_file = File.join(data_dir, username, 'analysis.json')
        expect(File.exist?(analysis_file)).to be true
      end

      it 'generates report file' do
        # Exercise
        analyzer.analyze_developer(username)

        # Verify
        report_file = File.join(data_dir, username, 'report.md')
        expect(File.exist?(report_file)).to be true
      end

      it 'extracts period information' do
        # Exercise
        result = analyzer.analyze_developer(username)

        # Verify
        aggregate_failures do
          expect(result[:period][:from]).to be_a(String)
          expect(result[:period][:to]).to be_a(String)
          expect(result[:period][:duration_days]).to be_a(Integer)
        end
      end
    end

    context 'when contribution data does not exist' do
      before do
        FileUtils.rm_f(contributions_file)
      end

      it 'raises DataNotFoundError' do
        # Exercise & Verify
        expect { analyzer.analyze_developer(username) }
          .to raise_error(IcMetrics::Errors::DataNotFoundError) do |error|
            aggregate_failures do
              expect(error.message).to include('No data found for developer')
              expect(error.message).to include(username)
            end
          end
      end
    end
  end

  describe '#generate_recommendations (private)' do
    let(:analyzer_instance) { described_class.new(config) }

    context 'with low commit count' do
      let(:data) do
        { 'summary' => { 'total_commits' => 5, 'total_prs' => 2, 'total_reviews' => 1, 'total_issues' => 0 } }
      end

      it 'includes commit frequency recommendation' do
        # Exercise
        recommendations = analyzer_instance.send(:generate_recommendations, data)

        # Verify
        expect(recommendations).to include(match(/increasing commit frequency/))
      end
    end

    context 'with no pull requests' do
      let(:data) do
        { 'summary' => { 'total_commits' => 20, 'total_prs' => 0, 'total_reviews' => 0, 'total_issues' => 1 } }
      end

      it 'includes PR recommendation' do
        # Exercise
        recommendations = analyzer_instance.send(:generate_recommendations, data)

        # Verify
        expect(recommendations).to include(match(/No pull requests found/))
      end
    end

    context 'with low review participation' do
      let(:data) do
        { 'summary' => { 'total_commits' => 20, 'total_prs' => 10, 'total_reviews' => 2, 'total_issues' => 5 } }
      end

      it 'includes review participation recommendation' do
        # Exercise
        recommendations = analyzer_instance.send(:generate_recommendations, data)

        # Verify
        expect(recommendations).to include(match(/code reviews/))
      end
    end

    context 'with no issues' do
      let(:data) do
        { 'summary' => { 'total_commits' => 20, 'total_prs' => 5, 'total_reviews' => 8, 'total_issues' => 0 } }
      end

      it 'includes issue engagement recommendation' do
        # Exercise
        recommendations = analyzer_instance.send(:generate_recommendations, data)

        # Verify
        expect(recommendations).to include(match(/engaging more with issues/))
      end
    end

    context 'with good metrics across the board' do
      let(:data) do
        { 'summary' => { 'total_commits' => 50, 'total_prs' => 10, 'total_reviews' => 15, 'total_issues' => 5 } }
      end

      it 'returns default positive message' do
        # Exercise
        recommendations = analyzer_instance.send(:generate_recommendations, data)

        # Verify
        expect(recommendations).to eq(['Great work on contributing to the codebase!'])
      end
    end
  end
end
