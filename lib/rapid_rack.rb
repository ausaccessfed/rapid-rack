module RapidRack
end

require 'rapid_rack/version'
require 'rapid_rack/authenticator'
require 'rapid_rack/default_receiver'
require 'rapid_rack/redis_registry'
require 'rapid_rack/engine' if defined?(Rails)
