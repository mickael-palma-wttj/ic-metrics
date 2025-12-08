# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::GithubClient do
  subject(:client) { described_class.new(config) }

  let(:config) { instance_double(IcMetrics::Config, github_token: 'test_token', organization: 'test-org') }
  let(:base_url) { 'https://api.github.com' }

  before do
    ENV.delete('DISABLE_SLEEP')
  end

  describe '#initialize' do
    it 'stores config values' do
      # Verify
      expect(client.instance_variable_get(:@token)).to eq('test_token')
      expect(client.instance_variable_get(:@organization)).to eq('test-org')
    end

    context 'when DISABLE_SLEEP is set' do
      before do
        ENV['DISABLE_SLEEP'] = 'true'
      end

      after do
        ENV.delete('DISABLE_SLEEP')
      end

      it 'sets disable_sleep flag' do
        # Exercise
        new_client = described_class.new(config)

        # Verify
        expect(new_client.instance_variable_get(:@disable_sleep)).to be true
      end
    end
  end

  describe '#request' do
    let(:endpoint) { '/test/endpoint' }
    let(:response_body) { '{"data": "value"}' }
    let(:response) { instance_double(Net::HTTPResponse, body: response_body, code: '200') }

    before do
      allow(client).to receive(:make_request).with(endpoint).and_return(response)
    end

    it 'makes request and parses JSON response' do
      # Exercise
      result = client.request(endpoint)

      # Verify
      aggregate_failures do
        expect(result).to eq({ 'data' => 'value' })
        expect(client).to have_received(:make_request).with(endpoint)
      end
    end
  end

  describe '#fetch_repositories' do
    let(:repos) { [{ 'name' => 'repo1' }, { 'name' => 'repo2' }] }

    before do
      allow(client).to receive(:get_paginated).with('/orgs/test-org/repos').and_return(repos)
    end

    it 'fetches organization repositories' do
      # Exercise
      result = client.fetch_repositories

      # Verify
      aggregate_failures do
        expect(result).to eq(repos)
        expect(client).to have_received(:get_paginated).with('/orgs/test-org/repos')
      end
    end
  end

  describe '#fetch_user_repositories' do
    let(:username) { 'testuser' }
    let(:repos) { [{ 'id' => 1, 'name' => 'repo1' }] }

    before do
      allow(client).to receive(:search_author_repositories).and_return(repos)
      allow(client).to receive(:search_pr_repositories).and_return([])
      allow(client).to receive(:search_issue_repositories).and_return([])
      allow(client).to receive(:fetch_reviewed_repositories).and_return([])
      allow(client).to receive(:fetch_commented_pr_repositories).and_return([])
      allow(client).to receive(:fetch_commented_issue_repositories).and_return([])
      allow(client).to receive(:fetch_user_activity_repositories).and_return([])
      allow($stdout).to receive(:puts)
    end

    it 'collects repositories from multiple sources' do
      # Exercise
      result = client.fetch_user_repositories(username)

      # Verify
      expect(result).to eq(repos)
    end

    it 'deduplicates repositories by id' do
      # Setup
      duplicate_repos = [{ 'id' => 1, 'name' => 'repo1' }, { 'id' => 1, 'name' => 'repo1' }]
      allow(client).to receive(:search_author_repositories).and_return(duplicate_repos)

      # Exercise
      result = client.fetch_user_repositories(username)

      # Verify
      expect(result.size).to eq(1)
    end

    context 'with since parameter' do
      let(:since_date) { '2025-01-01' }

      it 'passes since date to search methods' do
        # Exercise
        client.fetch_user_repositories(username, since: since_date)

        # Verify
        expect(client).to have_received(:fetch_reviewed_repositories).with(username, since_date)
      end
    end
  end

  describe '#fetch_commits' do
    let(:repo_name) { 'test-org/repo1' }
    let(:username) { 'testuser' }
    let(:commits) { [{ 'sha' => 'abc123' }] }

    before do
      allow(client).to receive(:get_paginated).and_return(commits)
    end

    it 'fetches commits for user in repository' do
      # Exercise
      result = client.fetch_commits(repo_name, username)

      # Verify
      aggregate_failures do
        expect(result).to eq(commits)
        expect(client).to have_received(:get_paginated)
          .with(match(/commits.*author=testuser/))
      end
    end

    context 'with since parameter' do
      let(:since_date) { Date.new(2025, 1, 1) }

      it 'includes since parameter in query' do
        # Exercise
        client.fetch_commits(repo_name, username, since: since_date)

        # Verify
        expect(client).to have_received(:get_paginated)
          .with(match(/since=2025-01-01/))
      end
    end
  end
end
