# frozen_string_literal: true

RSpec.configure do |config|
  # Configure expectation syntax
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Configure mock framework
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Use :apply_to_host_groups for shared context metadata
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
