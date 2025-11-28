module SpreeMultiVendor
  module Stock
    module CoordinatorDecorator
      def build_packages(packages = [])
        stock_locations_with_requested_variants.each do |stock_location|
          vendor_id = stock_location.vendor_id
          selected_inventory_units = vendor_id.present? ?
            find_vendor_inventory_units(inventory_units, vendor_id) :
            inventory_units

          packer = build_packer(stock_location, selected_inventory_units)
          packages += packer.packages
        end

        packages
      end

      private

      def find_vendor_inventory_units(inventory_units, vendor_id)
        inventory_units.find_all { |unit| unit.line_item.vendor_id == vendor_id }
      end
    end
  end
end

Spree::Stock::Coordinator.prepend(SpreeMultiVendor::Stock::CoordinatorDecorator)
