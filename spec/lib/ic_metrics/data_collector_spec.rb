# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::DataCollector do
  subject(:collector) { described_class.new(config) }

  let(:config) { instance_double(IcMetrics::Config, github_token: 'test_token', organization: 'test-org', data_directory: data_dir) }
  let(:data_dir) { '/tmp/test_data_collector' }
  let(:username) { 'testuser' }
  let(:client) { instance_double(IcMetrics::GithubClient) }

  before do
    allow(IcMetrics::GithubClient).to receive(:new).with(config).and_return(client)
    FileUtils.mkdir_p(data_dir)
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:print)
  end

  after do
    FileUtils.rm_rf(data_dir)
  end

  describe '#initialize' do
    it 'creates a GitHub client' do
      # Verify
      expect(collector.instance_variable_get(:@client)).to eq(client)
    end

    it 'stores configuration values' do
      # Verify
      aggregate_failures do
        expect(collector.instance_variable_get(:@config)).to eq(config)
        expect(collector.instance_variable_get(:@data_dir)).to eq(data_dir)
      end
    end

    context 'when MAX_PARALLEL_WORKERS is set' do
      before do
        ENV['MAX_PARALLEL_WORKERS'] = '8'
      end

      after do
        ENV.delete('MAX_PARALLEL_WORKERS')
      end

      it 'uses custom worker count' do
        # Exercise
        new_collector = described_class.new(config)

        # Verify
        expect(new_collector.instance_variable_get(:@max_workers)).to eq(8)
      end
    end

    context 'when MAX_PARALLEL_WORKERS is not set' do
      before do
        ENV.delete('MAX_PARALLEL_WORKERS')
      end

      it 'uses default worker count' do
        # Verify
        expect(collector.instance_variable_get(:@max_workers)).to eq(4)
      end
    end
  end

  describe '#collect_developer_data' do
    let(:repos) { [{ 'name' => 'repo1', 'full_name' => 'test-org/repo1' }] }
    let(:repo_data) do
      {
        commits: [],
        pull_requests: [],
        reviews: [],
        issues: [],
        pr_comments: [],
        issue_comments: []
      }
    end

    before do
      allow(client).to receive(:fetch_user_repositories).and_return(repos)
      allow(IcMetrics::Models::RepositoryData).to receive(:new).and_return(
        instance_double(IcMetrics::Models::RepositoryData, collect: repo_data)
      )
    end

    it 'creates developer directory' do
      # Exercise
      collector.collect_developer_data(username)

      # Verify
      expect(Dir.exist?(File.join(data_dir, username))).to be true
    end

    it 'fetches repositories for user' do
      # Exercise
      collector.collect_developer_data(username)

      # Verify
      expect(client).to have_received(:fetch_user_repositories).with(username, since: nil)
    end

    it 'saves contributions.json file' do
      # Exercise
      collector.collect_developer_data(username)

      # Verify
      contributions_file = File.join(data_dir, username, 'contributions.json')
      expect(File.exist?(contributions_file)).to be true
    end

    it 'returns contribution data structure' do
      # Exercise
      result = collector.collect_developer_data(username)

      # Verify
      aggregate_failures do
        expect(result).to be_a(Hash)
        expect(result[:developer]).to eq(username)
        expect(result[:organization]).to eq('test-org')
        expect(result[:summary]).to be_a(Hash)
        expect(result[:repositories]).to be_a(Hash)
      end
    end

    context 'with since parameter' do
      let(:since_date) { '2025-01-01' }

      it 'passes since date to client' do
        # Exercise
        collector.collect_developer_data(username, since: since_date)

        # Verify
        expect(client).to have_received(:fetch_user_repositories).with(username, since: since_date)
      end
    end

    context 'with until_date parameter' do
      let(:until_date) { '2025-12-31' }

      it 'collects data up to until_date' do
        # Exercise
        result = collector.collect_developer_data(username, until_date: until_date)

        # Verify
        expect(result).to be_a(Hash)
      end
    end

    context 'when no repositories found' do
      before do
        allow(client).to receive(:fetch_user_repositories).and_return([])
      end

      it 'returns empty data structure' do
        # Exercise
        result = collector.collect_developer_data(username)

        # Verify
        aggregate_failures do
          expect(result[:repositories]).to be_empty
          expect(result[:summary]).to be_a(Hash)
        end
      end
    end
  end
end
