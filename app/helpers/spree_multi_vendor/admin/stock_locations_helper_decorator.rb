module SpreeMultiVendor
  module Admin
    module StockLocationsHelperDecorator
      def available_stock_locations(opts = {})
        scope = super(opts)
        if opts[:vendor].present?
          scope.where(vendor: opts[:vendor])
        else
          scope.where(vendor_id: nil)
        end
      end

      def available_stock_locations_for_product(product)
        if product.vendor # Admin user editing vendor's product or vendor editing his own product
          product.vendor.stock_locations
        else # Admin user editing his own product
          available_stock_locations
        end
      end

      def default_stock_location_for_product(product)
        product.vendor.present? ? product.vendor.default_stock_location : super(product)
      end
    end
  end
end

Spree::Admin::StockLocationsHelper.prepend(SpreeMultiVendor::Admin::StockLocationsHelperDecorator)
