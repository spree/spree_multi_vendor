module Spree
  module V2
    module Storefront
      class OrderSerializer < CartSerializer
        set_type :order

        has_many :line_items, &:all_line_items
        has_many :variants, &:all_variants
        has_many :shipments, &:all_shipments
        has_many :vendors, &:all_vendors
      end
    end
  end
end
