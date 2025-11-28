module SpreeMultiVendor
  module V2
    module Storefront
      module CartSerializerDecorator
        def self.prepended(base)
          base.has_many :vendors, &:all_vendors
        end
      end
    end
  end
end

Spree::V2::Storefront::CartSerializer.prepend(SpreeMultiVendor::V2::Storefront::CartSerializerDecorator)
