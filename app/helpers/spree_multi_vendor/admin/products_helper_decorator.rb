module SpreeMultiVendor
  module Admin
    module ProductsHelperDecorator
      def variant_form_stock_location_options
        options_for_select(available_stock_locations_list(vendor: @product.vendor))
      end

      def product_list_filters_search_form_path
        [:admin, @vendor, @search]
      end
    end
  end
end

Spree::Admin::ProductsHelper.prepend(SpreeMultiVendor::Admin::ProductsHelperDecorator)
