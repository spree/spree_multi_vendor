module SpreeMultiVendor
  module V2
    module Storefront
      module ProductSerializerDecorator
        def self.prepended(base)
          base.belongs_to :vendor
          base.belongs_to :shipping_category

          base.has_many :shipping_methods do |product|
            product.shipping_methods.available_on_front_end
          end
        end
      end
    end
  end
end

Spree::V2::Storefront::ProductSerializer.prepend(SpreeMultiVendor::V2::Storefront::ProductSerializerDecorator)
