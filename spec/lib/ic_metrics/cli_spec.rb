# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::CLI do
  subject(:cli) { described_class.new }

  let(:config) { instance_double(IcMetrics::Config) }
  let(:command) { instance_double(IcMetrics::Commands::BaseCommand) }

  before do
    allow(IcMetrics::Config).to receive(:new).and_return(config)
    allow(IcMetrics::Commands::CommandFactory).to receive(:create).and_return(command)
    allow(command).to receive(:execute)
    allow($stdout).to receive(:puts)
  end

  describe '#run' do
    context 'with valid command' do
      let(:args) { %w[collect username] }

      it 'creates config and executes command' do
        # Exercise
        cli.run(args)

        # Verify
        aggregate_failures do
          expect(IcMetrics::Config).to have_received(:new)
          expect(IcMetrics::Commands::CommandFactory).to have_received(:create)
            .with('collect', config, ['username'])
          expect(command).to have_received(:execute)
        end
      end
    end

    context 'with ConfigurationError' do
      before do
        allow(IcMetrics::Config).to receive(:new)
          .and_raise(IcMetrics::Errors::ConfigurationError, 'Config error')
      end

      it 'prints error message and exits' do
        # Exercise & Verify
        expect { cli.run(['collect']) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect($stdout).to have_received(:puts).with('Configuration Error: Config error')
      end
    end

    context 'with RateLimitError' do
      let(:error) { IcMetrics::Errors::RateLimitError.new('Rate limit exceeded') }

      before do
        allow(error).to receive(:endpoint).and_return('/api/endpoint')
        allow(command).to receive(:execute).and_raise(error)
      end

      it 'prints rate limit message and exits' do
        # Exercise & Verify
        expect { cli.run(['collect']) }.to raise_error(SystemExit) do |exit_error|
          expect(exit_error.status).to eq(1)
        end
        expect($stdout).to have_received(:puts).with(/Rate limit exceeded/)
      end
    end

    context 'with AuthenticationError' do
      let(:error) { IcMetrics::Errors::AuthenticationError.new('Auth failed') }

      before do
        allow(error).to receive(:endpoint).and_return('/api/endpoint')
        allow(command).to receive(:execute).and_raise(error)
      end

      it 'prints authentication error and exits' do
        # Exercise & Verify
        expect { cli.run(['collect']) }.to raise_error(SystemExit) do |exit_error|
          expect(exit_error.status).to eq(1)
        end
        expect($stdout).to have_received(:puts).with(/Authentication failed/)
      end
    end

    context 'with DataNotFoundError' do
      before do
        allow(command).to receive(:execute)
          .and_raise(IcMetrics::Errors::DataNotFoundError, 'Data not found')
      end

      it 'prints error message and exits' do
        # Exercise & Verify
        expect { cli.run(['analyze']) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect($stdout).to have_received(:puts).with('Error: Data not found')
      end
    end

    context 'with InvalidDateFormatError' do
      before do
        allow(command).to receive(:execute)
          .and_raise(IcMetrics::Errors::InvalidDateFormatError, 'Invalid date')
      end

      it 'prints error message and exits' do
        # Exercise & Verify
        expect { cli.run(['collect']) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect($stdout).to have_received(:puts).with('Error: Invalid date')
      end
    end

    context 'with ApiError' do
      let(:error) { IcMetrics::Errors::ApiError.new('API error') }

      before do
        allow(error).to receive_messages(status_code: 500, endpoint: '/api/endpoint')
        allow(command).to receive(:execute).and_raise(error)
      end

      it 'prints API error details and exits' do
        # Exercise & Verify
        expect { cli.run(['collect']) }.to raise_error(SystemExit) do |exit_error|
          expect(exit_error.status).to eq(1)
        end
        expect($stdout).to have_received(:puts).with(/API request failed \(500\)/)
      end
    end

    context 'with generic Error' do
      before do
        allow(command).to receive(:execute)
          .and_raise(IcMetrics::Error, 'Generic error')
      end

      it 'prints error message and exits' do
        # Exercise & Verify
        expect { cli.run(['collect']) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect($stdout).to have_received(:puts).with('Error: Generic error')
      end
    end
  end
end
