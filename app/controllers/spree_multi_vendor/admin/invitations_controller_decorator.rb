module SpreeMultiVendor
  module Admin
    module InvitationsControllerDecorator
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

Spree::Admin::InvitationsController.prepend(SpreeMultiVendor::Admin::InvitationsControllerDecorator)
