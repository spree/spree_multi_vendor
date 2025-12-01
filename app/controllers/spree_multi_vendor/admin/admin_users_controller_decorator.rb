module SpreeMultiVendor
  module Admin
    module AdminUsersControllerDecorator
      def load_parent
        @parent = if current_vendor.present?
                      current_vendor
                    else
                      super
                    end
      end
    end
  end
end

Spree::Admin::AdminUsersController.prepend(SpreeMultiVendor::Admin::AdminUsersControllerDecorator)
