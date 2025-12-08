# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::Commands::BaseCommand do
  subject(:command) { TestCommand.new(config, args) }

  let(:config) { instance_double(IcMetrics::Config) }
  let(:args) { %w[arg1 arg2] }

  # Create a test subclass
  before do
    stub_const('TestCommand', Class.new(described_class) do
      def validate!
        # Default implementation for testing
      end

      def run
        # Default implementation for testing
      end
    end)
  end

  describe '#initialize' do
    it 'stores config and args' do
      # Verify
      aggregate_failures do
        expect(command.instance_variable_get(:@config)).to eq(config)
        expect(command.instance_variable_get(:@args)).to eq(args)
      end
    end
  end

  describe '#execute' do
    it 'calls validate! then run' do
      # Setup
      allow(command).to receive(:validate!)
      allow(command).to receive(:run)

      # Exercise
      command.execute

      # Verify
      aggregate_failures do
        expect(command).to have_received(:validate!)
        expect(command).to have_received(:run)
      end
    end

    context 'when validate! raises an error' do
      before do
        allow(command).to receive(:validate!).and_raise(StandardError, 'Validation failed')
      end

      it 'does not call run' do
        # Setup
        allow(command).to receive(:run)

        # Exercise & Verify
        expect { command.execute }.to raise_error(StandardError, 'Validation failed')
        expect(command).not_to have_received(:run)
      end
    end
  end

  describe '#validate!' do
    context 'when not implemented in subclass' do
      subject(:command) { NotImplementedCommand.new(config, args) }

      before do
        stub_const('NotImplementedCommand', Class.new(described_class))
      end

      it 'raises NotImplementedError' do
        # Exercise & Verify
        expect { command.send(:validate!) }
          .to raise_error(NotImplementedError, /must implement #validate!/)
      end
    end
  end

  describe '#run' do
    context 'when not implemented in subclass' do
      subject(:command) { NotImplementedCommand.new(config, args) }

      before do
        stub_const('NotImplementedCommand', Class.new(described_class) do
          def validate!; end
        end)
      end

      it 'raises NotImplementedError' do
        # Exercise & Verify
        expect { command.send(:run) }
          .to raise_error(NotImplementedError, /must implement #run/)
      end
    end
  end

  describe '#abort_with_error' do
    subject(:command) { TestCommand.new(config, args) }

    it 'prints error messages and exits with code 1' do
      # Setup
      allow(command).to receive(:puts)
      allow(command).to receive(:exit)

      # Exercise
      command.send(:abort_with_error, 'First error', 'Second error')

      # Verify
      aggregate_failures do
        expect(command).to have_received(:puts).with('Error: First error')
        expect(command).to have_received(:puts).with('Error: Second error')
        expect(command).to have_received(:exit).with(1)
      end
    end

    it 'handles single error message' do
      # Setup
      allow(command).to receive(:puts)
      allow(command).to receive(:exit)

      # Exercise
      command.send(:abort_with_error, 'Single error')

      # Verify
      aggregate_failures do
        expect(command).to have_received(:puts).with('Error: Single error')
        expect(command).to have_received(:exit).with(1)
      end
    end
  end
end
