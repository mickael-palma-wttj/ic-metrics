# frozen_string_literal: true

require 'bundler/setup'

# Load the main ic_metrics module which sets up Zeitwerk
# This must be loaded AFTER SimpleCov in coverage.rb
require_relative '../../lib/ic_metrics'

RSpec.configure do |config|
  # Add custom configuration here
end
