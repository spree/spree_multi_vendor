module SpreeMultiVendor
  module V2
    module Storefront
      module VendorizedModelsSerializerDecorator
        def self.prepended(base)
          base.belongs_to :vendor, serializer: ::Spree::V2::Storefront::VendorSerializer
        end
      end
    end
  end
end

Spree::V2::Storefront::ProductSerializer.prepend(SpreeMultiVendor::V2::Storefront::VendorizedModelsSerializerDecorator)

# cart serializers
Spree::V2::Storefront::LineItemSerializer.prepend(SpreeMultiVendor::V2::Storefront::VendorizedModelsSerializerDecorator)
Spree::V2::Storefront::ShipmentSerializer.prepend(SpreeMultiVendor::V2::Storefront::VendorizedModelsSerializerDecorator)
Spree::V2::Storefront::StockLocationSerializer.prepend(SpreeMultiVendor::V2::Storefront::VendorizedModelsSerializerDecorator)

# order serializers
Spree::V2::Storefront::OrderSerializer.prepend(SpreeMultiVendor::V2::Storefront::VendorizedModelsSerializerDecorator)
