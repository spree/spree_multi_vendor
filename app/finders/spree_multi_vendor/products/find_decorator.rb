module SpreeMultiVendor
  module Products
    module FindDecorator
      protected

      def by_vendor_ids(products)
        return products unless vendor_ids?

        products.where(vendor_id: vendor_ids)
      end
    end
  end
end

Spree::Products::Find.prepend(SpreeMultiVendor::Products::FindDecorator)
