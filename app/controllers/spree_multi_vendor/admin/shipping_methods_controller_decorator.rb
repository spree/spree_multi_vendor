module SpreeMultiVendor
  module Admin
    module ShippingMethodsControllerDecorator
      # for admin users we need to return only shipping methods without vendor
      def collection
        # for vendors we're returning vendor methods only
        return super.includes(:vendor).with_vendor(current_vendor.id).order(created_at: :asc) if current_vendor.present?

        super.without_vendor.order(created_at: :asc)
      end
    end
  end
end

Spree::Admin::ShippingMethodsController.prepend(SpreeMultiVendor::Admin::ShippingMethodsControllerDecorator)
