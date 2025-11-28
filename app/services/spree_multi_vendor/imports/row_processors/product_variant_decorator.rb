module SpreeMultiVendor
  module Imports
    module RowProcessors
      module ProductVariantDecorator
        def assign_attributes_to_product(product)
          product = super(product)
          product.vendor = import.owner if import.owner.is_a?(Spree::Vendor)
          product
        end
      end
    end
  end
end

Spree::Imports::RowProcessors::ProductVariant.prepend(SpreeMultiVendor::Imports::RowProcessors::ProductVariantDecorator)
