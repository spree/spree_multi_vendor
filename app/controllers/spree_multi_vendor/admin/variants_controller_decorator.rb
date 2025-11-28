module SpreeMultiVendor
  module Admin
    module VariantsControllerDecorator
      private

      def build_stock_items
        available_stock_locations(vendor: @product.vendor).each do |stock_location|
          @variant.stock_items.build(stock_location: stock_location) unless @variant.stock_items.exists?(stock_location: stock_location)
        end
      end
    end
  end
end

Spree::Admin::VariantsController.prepend(SpreeMultiVendor::Admin::VariantsControllerDecorator)
