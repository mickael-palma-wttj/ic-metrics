# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::Config do
  subject(:config) { described_class.new }

  describe '#initialize' do
    context 'when GITHUB_TOKEN is set' do
      # Setup
      before do
        ENV['GITHUB_TOKEN'] = 'test_token_123'
      end

      # Teardown
      after do
        ENV.delete('GITHUB_TOKEN')
        ENV.delete('GITHUB_ORG')
        ENV.delete('DATA_DIRECTORY')
      end

      it 'initializes with default values' do
        # Exercise & Verify
        aggregate_failures do
          expect(config.github_token).to eq('test_token_123')
          expect(config.organization).to eq('WTTJ')
          expect(config.data_directory).to include('data')
        end
      end

      context 'with custom GITHUB_ORG' do
        # Setup
        before do
          ENV['GITHUB_ORG'] = 'custom-org'
        end

        it 'uses the custom organization' do
          # Exercise & Verify
          expect(config.organization).to eq('custom-org')
        end
      end

      context 'with custom DATA_DIRECTORY' do
        # Setup
        let(:custom_dir) { '/tmp/test_data' }

        before do
          ENV['DATA_DIRECTORY'] = custom_dir
        end

        it 'uses the custom data directory' do
          # Exercise & Verify
          expect(config.data_directory).to eq(custom_dir)
        end
      end

      context 'when data directory does not exist' do
        # Setup
        let(:temp_dir) { "/tmp/ic_metrics_test_#{Time.now.to_i}" }

        before do
          ENV['DATA_DIRECTORY'] = temp_dir
          FileUtils.rm_rf(temp_dir)
        end

        # Teardown
        after do
          FileUtils.rm_rf(temp_dir)
        end

        it 'creates the data directory' do
          # Exercise
          described_class.new

          # Verify
          expect(Dir.exist?(temp_dir)).to be true
        end
      end
    end

    context 'when GITHUB_TOKEN is not set' do
      # Setup
      before do
        ENV.delete('GITHUB_TOKEN')
      end

      it 'raises ConfigurationError with setup instructions' do
        # Exercise & Verify
        expect { config }.to raise_error(IcMetrics::Errors::ConfigurationError) do |error|
          aggregate_failures do
            expect(error.message).to include('GITHUB_TOKEN environment variable is required')
            expect(error.message).to include('Create a GitHub Personal Access Token')
            expect(error.message).to include("Grant 'repo' and 'read:org' scopes")
          end
        end
      end
    end
  end
end
