module RapidRack
  RSpec.describe Engine, type: :feature do
    let(:opts) { YAML.load_file('spec/dummy/config/rapidconnect.yml') }
    let(:issuer) { opts['issuer'] }
    let(:audience) { opts['audience'] }
    let(:url) { opts['url'] }
    let(:secret) { opts['secret'] }
    let(:handler) { nil }
    let(:app) { Rails.application }

    # Unfortunately the neatest way to get access to a routed application in
    # the engine.
    let(:engine_app) { RapidRack::Engine.routes.routes.routes[0].app }

    subject { last_response }

    before do
      val = handler.try(:constantize).try(:new) || engine_app
      engine_app.instance_variable_set(:@error_handler, val)
    end

    it_behaves_like 'an authenticator'
  end
end
