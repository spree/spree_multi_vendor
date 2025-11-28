module SpreeMultiVendor
  module Admin
    module ImportsControllerDecorator
      def set_owner
        if current_vendor.present?
          @object.owner = current_vendor
        else
          super
        end
      end
    end
  end
end

Spree::Admin::ImportsController.prepend(SpreeMultiVendor::Admin::ImportsControllerDecorator)
