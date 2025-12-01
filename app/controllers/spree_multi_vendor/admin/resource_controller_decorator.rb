module SpreeMultiVendor
  module Admin
    module ResourceControllerDecorator
      protected

      def build_resource
        resource = super
        resource.vendor = current_vendor if resource.has_attribute?(:vendor_id)
        resource
      end
    end
  end
end

Spree::Admin::ResourceController.prepend(SpreeMultiVendor::Admin::ResourceControllerDecorator)
