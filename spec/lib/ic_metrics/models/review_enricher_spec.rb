# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::Models::ReviewEnricher do
  describe '#enrich' do
    context 'when reviews have empty bodies and are COMMENTED' do
      let(:reviews) do
        [
          { 'id' => 1, 'body' => '', 'state' => 'COMMENTED' },
          { 'id' => 2, 'body' => 'Has content', 'state' => 'COMMENTED' }
        ]
      end

      let(:comments) do
        [
          { 'pull_request_review_id' => 1, 'body' => 'Comment 1' },
          { 'pull_request_review_id' => 1, 'body' => 'Comment 2' }
        ]
      end

      it 'enriches reviews with comment bodies' do
        # Setup
        enricher = described_class.new(reviews, comments)

        # Exercise
        result = enricher.enrich

        # Verify
        aggregate_failures do
          expect(result[0]['body']).to eq("Comment 1\n---\nComment 2")
          expect(result[1]['body']).to eq('Has content')
        end
      end
    end

    context 'when review is not COMMENTED' do
      let(:reviews) do
        [{ 'id' => 1, 'body' => '', 'state' => 'APPROVED' }]
      end

      let(:comments) do
        [{ 'pull_request_review_id' => 1, 'body' => 'Comment 1' }]
      end

      it 'does not enrich review' do
        # Setup
        enricher = described_class.new(reviews, comments)

        # Exercise
        result = enricher.enrich

        # Verify
        expect(result[0]['body']).to eq('')
      end
    end

    context 'when review has no matching comments' do
      let(:reviews) do
        [{ 'id' => 1, 'body' => '', 'state' => 'COMMENTED' }]
      end

      let(:comments) { [] }

      it 'does not modify review body' do
        # Setup
        enricher = described_class.new(reviews, comments)

        # Exercise
        result = enricher.enrich

        # Verify
        expect(result[0]['body']).to eq('')
      end
    end
  end
end
