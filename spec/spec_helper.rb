require 'simplecov'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../dummy/config/environment.rb', __FILE__)

require 'rspec/rails'
require 'capybara/rspec'
require 'fakeredis'

require 'rapid_rack'

Dir['./spec/support/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    load Rails.root.join('db/schema.rb')
  end

  config.before { Redis::Connection::Memory.reset_all_databases }

  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      fail ActiveRecord::Rollback
    end
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed

  config.include Rack::Test::Methods
  config.include TemporaryTestClass
end
