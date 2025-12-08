# frozen_string_literal: true

# SimpleCov must be loaded FIRST before any application code
require 'simplecov'

SimpleCov.start do
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
end
