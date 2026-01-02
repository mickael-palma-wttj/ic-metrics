# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::Utils::ContentChunker do
  describe '.chunk' do
    context 'when content is smaller than max_size' do
      let(:content) { "line1\nline2\nline3\n" }
      let(:max_size) { 1000 }

      it 'returns content as single chunk' do
        result = described_class.chunk(content, max_size)

        expect(result).to eq([content])
      end
    end

    context 'when content exceeds max_size' do
      let(:content) { "line1\nline2\nline3\nline4\nline5\n" }
      let(:max_size) { 12 }

      it 'splits content into multiple chunks' do
        result = described_class.chunk(content, max_size)

        expect(result.size).to be > 1
      end

      it 'splits at line boundaries' do
        result = described_class.chunk(content, max_size)

        expect(result).to all(end_with("\n"))
      end

      it 'preserves all content' do
        result = described_class.chunk(content, max_size)

        expect(result.join).to eq(content)
      end
    end

    context 'when a single line exceeds max_size' do
      let(:content) { "short\n#{'x' * 100}\nshort\n" }
      let(:max_size) { 50 }

      it 'includes oversized line as its own chunk' do
        result = described_class.chunk(content, max_size)

        expect(result.join).to eq(content)
      end
    end

    context 'with empty content' do
      let(:content) { '' }
      let(:max_size) { 100 }

      it 'returns single chunk as content fits within limit' do
        result = described_class.chunk(content, max_size)

        expect(result).to eq([content])
      end
    end

    context 'with exact max_size content' do
      let(:content) { 'x' * 100 }
      let(:max_size) { 100 }

      it 'returns single chunk' do
        result = described_class.chunk(content, max_size)

        expect(result).to eq([content])
      end
    end
  end

  describe '.part_name' do
    context 'when there is only one chunk' do
      it 'returns original filename' do
        result = described_class.part_name('data.csv', 0, 1)

        expect(result).to eq('data.csv')
      end
    end

    context 'when there are multiple chunks' do
      it 'returns filename with part indicator' do
        result = described_class.part_name('data.csv', 0, 3)

        expect(result).to eq('data.csv (Part 1/3)')
      end

      it 'uses 1-based indexing for display' do
        result = described_class.part_name('data.csv', 2, 5)

        expect(result).to eq('data.csv (Part 3/5)')
      end
    end
  end
end
