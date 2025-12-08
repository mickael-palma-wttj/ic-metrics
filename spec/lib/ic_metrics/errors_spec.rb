# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::Errors do
  describe IcMetrics::Errors::ConfigurationError do
    subject(:error) { described_class.new(message) }

    let(:message) { 'Configuration is invalid' }

    it 'inherits from IcMetrics::Error' do
      # Verify
      expect(error).to be_a(IcMetrics::Error)
    end

    it 'stores the error message' do
      # Verify
      expect(error.message).to eq(message)
    end

    it 'can be raised and caught' do
      # Exercise & Verify
      expect { raise described_class, message }.to raise_error(described_class, message)
    end
  end

  describe IcMetrics::Errors::DataNotFoundError do
    subject(:error) { described_class.new(message) }

    let(:message) { 'Data not found' }

    it 'inherits from IcMetrics::Error' do
      # Verify
      expect(error).to be_a(IcMetrics::Error)
    end

    it 'stores the error message' do
      # Verify
      expect(error.message).to eq(message)
    end
  end

  describe IcMetrics::Errors::ApiError do
    subject(:error) { described_class.new(message) }

    let(:message) { 'API request failed' }

    it 'inherits from IcMetrics::Error' do
      # Verify
      expect(error).to be_a(IcMetrics::Error)
    end

    it 'stores the error message' do
      # Verify
      expect(error.message).to eq(message)
    end
  end

  describe IcMetrics::Errors::AuthenticationError do
    subject(:error) { described_class.new(message) }

    let(:message) { 'Authentication failed' }

    it 'inherits from IcMetrics::Error' do
      # Verify
      expect(error).to be_a(IcMetrics::Error)
    end
  end

  describe IcMetrics::Errors::RateLimitError do
    subject(:error) { described_class.new(message) }

    let(:message) { 'Rate limit exceeded' }

    it 'inherits from IcMetrics::Error' do
      # Verify
      expect(error).to be_a(IcMetrics::Error)
    end
  end

  describe IcMetrics::Errors::ResourceNotFoundError do
    subject(:error) { described_class.new(message) }

    let(:message) { 'Resource not found' }

    it 'inherits from IcMetrics::Error' do
      # Verify
      expect(error).to be_a(IcMetrics::Error)
    end
  end

  describe IcMetrics::Errors::InvalidDateFormatError do
    subject(:error) { described_class.new(message) }

    let(:message) { 'Invalid date format' }

    it 'inherits from IcMetrics::Error' do
      # Verify
      expect(error).to be_a(IcMetrics::Error)
    end
  end
end
