require File.expand_path('../boot', __FILE__)

require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)
require 'rapid_rack'

require_relative '../lib/test_receiver'
require_relative '../lib/test_error_handler'

module Dummy
  class Application < Rails::Application
    config.cache_classes = true
    config.eager_load = false

    config.consider_all_requests_local = true
    config.action_dispatch.show_exceptions = false

    config.rapid_rack.receiver = 'TestReceiver'
    config.rapid_rack.error_handler = 'TestErrorHandler'
  end
end
