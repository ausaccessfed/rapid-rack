RapidRack::Engine.routes.draw do
  opts = Rails.application.config.rapid_rack
  authenticator = opts.authenticator.constantize.new(opts)

  mount authenticator => ''
end
