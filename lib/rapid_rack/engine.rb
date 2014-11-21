require 'yaml'

module RapidRack
  class Engine < ::Rails::Engine
    isolate_namespace RapidRack

    configure do
      config.rapid_rack = OpenStruct.new
    end

    initializer 'rapid_rack.build_rack_application' do
      config.rapid_rack = OpenStruct.new(configuration)
      config.rapid_rack.authenticator = authenticator
    end

    def configuration
      return @configuration if @configuration

      file = Rails.root.join('config/rapidconnect.yml')
      fail("Missing configuration: #{file}") unless File.exist?(file)

      opts_from_file = YAML.load_file(file).symbolize_keys
      opts_from_app = config.rapid_rack.to_h

      @configuration = opts_from_file.merge(opts_from_app)
    end

    def authenticator
      return 'RapidRack::MockAuthenticator' if configuration[:development_mode]
      'RapidRack::Authenticator'
    end
  end
end
