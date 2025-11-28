# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require 'dotenv/load'

require File.expand_path('../dummy/config/environment.rb', __FILE__)

require 'spree_dev_tools/rspec/spec_helper'

require 'spree_multi_vendor/factories'

require 'cancan/matchers'
require 'spree/testing_support/ability_helpers'

require 'spree/testing_support/next_instance_of'
require 'spree/testing_support/capybara_config'

require 'spree/admin/testing_support/capybara_utils'

require 'spree_multi_vendor/testing_support/authorization_helpers'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].sort.each { |f| require f }

def json_response
  case body = JSON.parse(response.body)
  when Hash
    body.with_indifferent_access
  when Array
    body
  end
end

RSpec.configure do |config|
  config.include Spree::Admin::TestingSupport::CapybaraUtils

  config.example_status_persistence_file_path = '.rspec_status'
  Capybara.test_id = 'data-test-id'
end
