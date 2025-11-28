module SpreeMultiVendor
  module Vendors
    class ActivateProductsJob < ::SpreeMultiVendor::BaseJob
      def perform(vendor_id)
        vendor = Spree::Vendor.find(vendor_id)

        paused_products = vendor.products.paused
        draft_products = vendor.products.draft

        paused_products.or(draft_products).find_in_batches do |group|
          group.each(&:activate!)
        end
      end
    end
  end
end
