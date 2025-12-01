module SpreeMultiVendor
  module Stock
    module PackageDecorator
      def shipping_methods
        if stock_location.vendor_id.present?
          super.to_a.find_all { |sm| sm.vendor_id == stock_location.vendor_id }
        else
          super.to_a.find_all { |sm| sm.vendor_id.blank? }
        end
      end
    end
  end
end

Spree::Stock::Package.prepend(SpreeMultiVendor::Stock::PackageDecorator)
