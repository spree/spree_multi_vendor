module SpreeMultiVendor
  module Admin
    module RoleUsersControllerDecorator
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

Spree::Admin::RoleUsersController.prepend(SpreeMultiVendor::Admin::RoleUsersControllerDecorator)
