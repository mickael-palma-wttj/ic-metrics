# frozen_string_literal: true

require "zeitwerk"
require "net/http"
require "uri"
require "json"
require "fileutils"
require "date"
require "time"
require "set"
require "dotenv/load"

module IcMetrics
  class Error < StandardError; end
end

# Setup Zeitwerk autoloader
loader = Zeitwerk::Loader.for_gem
loader.setup
