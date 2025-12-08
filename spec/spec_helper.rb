# frozen_string_literal: true

# Load support files in alphabetical order
# Note: 00_simplecov.rb loads first to ensure coverage tracking before application code
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }
