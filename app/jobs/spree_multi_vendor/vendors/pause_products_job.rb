module SpreeMultiVendor
  module Vendors
    class PauseProductsJob < ::SpreeMultiVendor::BaseJob
      def perform(vendor_id)
        vendor = Spree::Vendor.find(vendor_id)

        vendor.products.active.find_in_batches do |group|
          group.each(&:pause!)
        end
      end
    end
  end
end
