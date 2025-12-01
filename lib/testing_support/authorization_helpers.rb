module SpreeMultiVendor
  module AuthorizationHelpers
    module Controller
      def stub_vendor_authorization!
        stub_authorization!
        let(:admin_user) { vendor.users.first || create(:vendor_user, vendor: vendor) }
      end
    end

    module Request
      def stub_vendor_authorization!
        stub_authorization!
        let(:admin_user) { vendor.users.first || create(:vendor_user, vendor: vendor) }
      end
    end
  end
end

RSpec.configure do |config|
  config.extend SpreeMultiVendor::AuthorizationHelpers::Controller, type: :controller
  config.extend SpreeMultiVendor::AuthorizationHelpers::Request, type: :feature
  config.extend SpreeMultiVendor::AuthorizationHelpers::Request, type: :request
  config.extend Spree::TestingSupport::AuthorizationHelpers::Request, type: :request
end
