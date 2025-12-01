module SpreeMultiVendor
  module Api
    module V2
      module Platform
        module OrdersControllerDecorator
          def scope
            if action_name == 'index'
              super.without_vendor
            else
              super
            end
          end
        end
      end
    end
  end
end

Spree::Api::V2::Platform::OrdersController.prepend(SpreeMultiVendor::Api::V2::Platform::OrdersControllerDecorator)
