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
      expect(client.organization).to eq('test-org')
    end

    context 'when DISABLE_SLEEP is set' do
      before do
        ENV['DISABLE_SLEEP'] = 'true'
      end

      after do
        ENV.delete('DISABLE_SLEEP')
      end

      it 'creates rate limiter with disabled flag' do
        # Exercise
        new_client = described_class.new(config)

        # Verify
        rate_limiter = new_client.instance_variable_get(:@rate_limiter)
        expect(rate_limiter.instance_variable_get(:@disabled)).to be true
      end
    end
  end

  describe '#request' do
    subject(:test_client) { described_class.new(config) }

    let(:endpoint) { '/test/endpoint' }
    let(:response_body) { '{"data": "value"}' }
    let(:response) { instance_double(Net::HTTPResponse, body: response_body, code: '200') }
    let(:http_client) { instance_double(IcMetrics::Services::HttpClient) }

    before do
      allow(IcMetrics::Services::HttpClient).to receive(:new).and_return(http_client)
      allow(http_client).to receive(:get).with(endpoint).and_return(response)
    end

    it 'makes request and parses JSON response' do
      # Exercise
      result = test_client.request(endpoint)

      # Verify
      aggregate_failures do
        expect(result).to eq({ 'data' => 'value' })
        expect(http_client).to have_received(:get).with(endpoint)
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
    let(:repository_aggregator) { instance_double(IcMetrics::Services::RepositoryAggregator) }

    before do
      allow(IcMetrics::Services::RepositoryAggregator).to receive(:new).and_return(repository_aggregator)
      allow(repository_aggregator).to receive(:aggregate_user_repositories).and_return(repos)
      allow($stdout).to receive(:puts)
    end

    it 'delegates to repository aggregator' do
      # Exercise
      result = client.fetch_user_repositories(username)

      # Verify
      aggregate_failures do
        expect(result).to eq(repos)
        expect(repository_aggregator).to have_received(:aggregate_user_repositories)
          .with(username, nil)
      end
    end

    context 'with since parameter' do
      let(:since_date) { Date.new(2025, 1, 1) }

      it 'passes since date to aggregator' do
        # Exercise
        client.fetch_user_repositories(username, since: since_date)

        # Verify
        expect(repository_aggregator).to have_received(:aggregate_user_repositories)
          .with(username, since_date)
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
