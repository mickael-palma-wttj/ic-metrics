# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::Services::RateLimiter do
  describe '.standard' do
    it 'creates limiter with 0.1 second delay' do
      # Exercise
      limiter = described_class.standard

      # Verify
      expect(limiter.instance_variable_get(:@delay)).to eq(0.1)
    end

    context 'when DISABLE_SLEEP is true' do
      before do
        ENV['DISABLE_SLEEP'] = 'true'
      end

      after do
        ENV.delete('DISABLE_SLEEP')
      end

      it 'creates limiter with disabled flag' do
        # Exercise
        limiter = described_class.standard

        # Verify
        expect(limiter.instance_variable_get(:@disabled)).to be true
      end
    end
  end

  describe '.search' do
    it 'creates limiter with 1 second delay' do
      # Exercise
      limiter = described_class.search

      # Verify
      expect(limiter.instance_variable_get(:@delay)).to eq(1.0)
    end
  end

  describe '#wait' do
    subject(:limiter) { described_class.new(delay: 0.1, disabled: false) }

    it 'sleeps for configured delay' do
      # Setup
      allow(limiter).to receive(:sleep)

      # Exercise
      limiter.wait

      # Verify
      expect(limiter).to have_received(:sleep).with(0.1)
    end

    context 'when disabled' do
      subject(:limiter) { described_class.new(delay: 0.1, disabled: true) }

      it 'does not sleep' do
        # Setup
        allow(limiter).to receive(:sleep)

        # Exercise
        limiter.wait

        # Verify
        expect(limiter).not_to have_received(:sleep)
      end
    end
  end
end
