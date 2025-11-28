module SpreeMultiVendor
  module Vendors
    class ArchiveProductsJob < ::SpreeMultiVendor::BaseJob
      def perform(vendor_id)
        vendor = Spree::Vendor.find(vendor_id)
        vendor.products.archivable.find_each(&:archive)
      end
    end
  end
end
