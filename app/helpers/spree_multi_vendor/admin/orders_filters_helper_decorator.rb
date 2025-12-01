module SpreeMultiVendor
  module Admin
    module OrdersFiltersHelperDecorator
      def load_vendor
        @vendor = Spree::Vendor.friendly.find(params[:vendor_id]) if params[:vendor_id].present? && !current_vendor.present?
      end
    end
  end
end

Spree::Admin::OrdersFiltersHelper.prepend(SpreeMultiVendor::Admin::OrdersFiltersHelperDecorator)
