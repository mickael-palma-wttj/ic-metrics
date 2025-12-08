# frozen_string_literal: true

require 'bundler/setup'

# Load the main ic_metrics module which sets up Zeitwerk
# This must be loaded AFTER SimpleCov in coverage.rb
require_relative '../lib/ic_metrics'

# Eager load all constants for testing
# This ensures all classes are loaded before tests run
Zeitwerk::Loader.eager_load_all

# Require RSpec first to ensure it's available when support files load
require 'rspec'

# Load support files in alphabetical order
# Note: 00_simplecov.rb loads first to ensure coverage tracking before application code
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }
