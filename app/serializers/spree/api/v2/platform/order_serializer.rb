module Spree
  module Api
    module V2
      module Platform
        class OrderSerializer < BaseSerializer
          attributes :number, :item_total, :total, :total_minus_store_credits, :display_total_minus_store_credits, :ship_total, :adjustment_total, :created_at,
                     :updated_at, :completed_at, :included_tax_total, :additional_tax_total, :display_additional_tax_total,
                     :display_included_tax_total, :tax_total, :currency, :state, :token, :email,
                     :display_item_total, :display_ship_total, :display_adjustment_total, :display_tax_total,
                     :promo_total, :display_promo_total, :item_count, :special_instructions, :display_total,
                     :pre_tax_item_amount, :display_pre_tax_item_amount, :pre_tax_total, :display_pre_tax_total,
                     :shipment_state, :payment_state, :public_metadata

          belongs_to :user

          belongs_to :bill_address, serializer: AddressSerializer
          belongs_to :ship_address, serializer: AddressSerializer

          has_many :line_items
          has_many :shipments
          has_many :adjustments
          has_many :all_adjustments, serializer: :adjustments, type: :adjustment

          has_many :order_promotions

          belongs_to :vendor, if: ->(order) { order.suborder? }
          has_many :vendors, if: ->(order) { order.parent_order? } do |order|
            order.vendor_orders.any? ? order.vendor_order_vendors : order.vendors
          end

          has_many :vendor_orders, if: ->(order) { order.parent_order? }, serializer: :order, type: :order
        end
      end
    end
  end
end
