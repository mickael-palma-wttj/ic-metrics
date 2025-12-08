# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::Services::ResponseHandler do
  describe '.handle' do
    let(:endpoint) { '/test/endpoint' }

    context 'with 200 status' do
      let(:response) { instance_double(Net::HTTPResponse, code: '200') }

      it 'returns the response' do
        # Exercise
        result = described_class.handle(response, endpoint)

        # Verify
        expect(result).to eq(response)
      end
    end

    context 'with 404 status' do
      let(:response) { instance_double(Net::HTTPResponse, code: '404') }

      it 'raises ResourceNotFoundError' do
        # Exercise & Verify
        expect { described_class.handle(response, endpoint) }
          .to raise_error(IcMetrics::Errors::ResourceNotFoundError) do |error|
            expect(error.status_code).to eq(404)
            expect(error.endpoint).to eq(endpoint)
          end
      end
    end

    context 'with 403 status' do
      let(:response) { instance_double(Net::HTTPResponse, code: '403') }

      it 'raises RateLimitError' do
        # Exercise & Verify
        expect { described_class.handle(response, endpoint) }
          .to raise_error(IcMetrics::Errors::RateLimitError) do |error|
            expect(error.status_code).to eq(403)
            expect(error.endpoint).to eq(endpoint)
          end
      end
    end

    context 'with 401 status' do
      let(:response) { instance_double(Net::HTTPResponse, code: '401') }

      it 'raises AuthenticationError' do
        # Exercise & Verify
        expect { described_class.handle(response, endpoint) }
          .to raise_error(IcMetrics::Errors::AuthenticationError) do |error|
            expect(error.status_code).to eq(401)
            expect(error.endpoint).to eq(endpoint)
          end
      end
    end

    context 'with 500 status' do
      let(:response) { instance_double(Net::HTTPResponse, code: '500', body: 'Server error') }

      it 'raises ApiError' do
        # Exercise & Verify
        expect { described_class.handle(response, endpoint) }
          .to raise_error(IcMetrics::Errors::ApiError) do |error|
            expect(error.status_code).to eq(500)
            expect(error.endpoint).to eq(endpoint)
            expect(error.message).to include('Server error')
          end
      end
    end
  end
end
