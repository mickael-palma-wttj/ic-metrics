# frozen_string_literal: true

# SimpleCov must be loaded FIRST before any application code
require 'simplecov'
require 'simplecov-json'

SimpleCov.start do
  # Generate both HTML and JSON reports
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])

  add_filter '/spec/'
  add_filter '/bin/'
  add_filter '/examples/'

  add_group 'Commands', 'lib/ic_metrics/commands'
  add_group 'Analyzers', 'lib/ic_metrics/analyzers'
  add_group 'Services', 'lib/ic_metrics/services'
  add_group 'Models', 'lib/ic_metrics/models'
  add_group 'Presenters', 'lib/ic_metrics/presenters'
  add_group 'Utils', 'lib/ic_metrics/utils'

  minimum_coverage 80
  
  # Configure coverage directory
  coverage_dir 'coverage'
end
