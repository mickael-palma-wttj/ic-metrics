# frozen_string_literal: true

require 'zeitwerk'
require 'net/http'
require 'uri'
require 'json'
require 'fileutils'
require 'date'
require 'time'
require 'dotenv/load'
require 'concurrent-ruby'

module IcMetrics
  class Error < StandardError; end
end

# Setup Zeitwerk autoloader
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect('cli' => 'CLI')
loader.setup
