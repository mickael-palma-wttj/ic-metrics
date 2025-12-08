# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IcMetrics::Utils::DateFilter do
  describe '.format_for_search' do
    context 'with Date object' do
      let(:date) { Date.new(2025, 12, 8) }

      it 'formats as YYYY-MM-DD' do
        # Exercise
        result = described_class.format_for_search(date)

        # Verify
        expect(result).to eq('2025-12-08')
      end
    end

    context 'with Time object' do
      let(:time) { Time.new(2025, 1, 15, 10, 30, 0) }

      it 'formats as YYYY-MM-DD' do
        # Exercise
        result = described_class.format_for_search(time)

        # Verify
        expect(result).to eq('2025-01-15')
      end
    end

    context 'with string' do
      let(:date_string) { '2025-06-20' }

      it 'parses and formats as YYYY-MM-DD' do
        # Exercise
        result = described_class.format_for_search(date_string)

        # Verify
        expect(result).to eq('2025-06-20')
      end
    end
  end

  describe '.within_range?' do
    let(:timestamp) { '2025-06-15T10:00:00Z' }

    context 'with no date constraints' do
      it 'returns true' do
        # Exercise
        result = described_class.within_range?(timestamp, nil, nil)

        # Verify
        expect(result).to be true
      end
    end

    context 'with since_date only' do
      let(:since_date) { Date.new(2025, 6, 1) }

      context 'when timestamp is after since_date' do
        it 'returns true' do
          # Exercise
          result = described_class.within_range?(timestamp, since_date, nil)

          # Verify
          expect(result).to be true
        end
      end

      context 'when timestamp is before since_date' do
        let(:timestamp) { '2025-05-15T10:00:00Z' }

        it 'returns false' do
          # Exercise
          result = described_class.within_range?(timestamp, since_date, nil)

          # Verify
          expect(result).to be false
        end
      end
    end

    context 'with until_date only' do
      let(:until_date) { Date.new(2025, 12, 31) }

      context 'when timestamp is before until_date' do
        it 'returns true' do
          # Exercise
          result = described_class.within_range?(timestamp, nil, until_date)

          # Verify
          expect(result).to be true
        end
      end

      context 'when timestamp is after until_date' do
        let(:timestamp) { '2026-01-15T10:00:00Z' }

        it 'returns false' do
          # Exercise
          result = described_class.within_range?(timestamp, nil, until_date)

          # Verify
          expect(result).to be false
        end
      end
    end

    context 'with both since_date and until_date' do
      let(:since_date) { Date.new(2025, 6, 1) }
      let(:until_date) { Date.new(2025, 6, 30) }

      context 'when timestamp is within range' do
        it 'returns true' do
          # Exercise
          result = described_class.within_range?(timestamp, since_date, until_date)

          # Verify
          expect(result).to be true
        end
      end

      context 'when timestamp is before range' do
        let(:timestamp) { '2025-05-15T10:00:00Z' }

        it 'returns false' do
          # Exercise
          result = described_class.within_range?(timestamp, since_date, until_date)

          # Verify
          expect(result).to be false
        end
      end

      context 'when timestamp is after range' do
        let(:timestamp) { '2025-07-15T10:00:00Z' }

        it 'returns false' do
          # Exercise
          result = described_class.within_range?(timestamp, since_date, until_date)

          # Verify
          expect(result).to be false
        end
      end
    end
  end

  describe '.normalize_date' do
    context 'with Date object' do
      let(:date) { Date.new(2025, 12, 8) }

      it 'returns the date unchanged' do
        # Exercise
        result = described_class.normalize_date(date)

        # Verify
        expect(result).to eq(date)
      end
    end

    context 'with Time object' do
      let(:time) { Time.new(2025, 1, 15, 10, 30, 0) }

      it 'converts to Date' do
        # Exercise
        result = described_class.normalize_date(time)

        # Verify
        aggregate_failures do
          expect(result).to be_a(Date)
          expect(result).to eq(Date.new(2025, 1, 15))
        end
      end
    end

    context 'with string' do
      let(:date_string) { '2025-06-20' }

      it 'parses to Date' do
        # Exercise
        result = described_class.normalize_date(date_string)

        # Verify
        aggregate_failures do
          expect(result).to be_a(Date)
          expect(result).to eq(Date.new(2025, 6, 20))
        end
      end
    end
  end

  describe '.normalize_time' do
    context 'with Date object' do
      let(:date) { Date.new(2025, 12, 8) }

      it 'converts to Time' do
        # Exercise
        result = described_class.normalize_time(date)

        # Verify
        expect(result).to be_a(Time)
      end
    end

    context 'with Time object' do
      let(:time) { Time.new(2025, 1, 15, 10, 30, 0) }

      it 'returns time unchanged' do
        # Exercise
        result = described_class.normalize_time(time)

        # Verify
        expect(result).to eq(time)
      end
    end
  end
end
