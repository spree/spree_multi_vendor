module SpreeMultiVendor
  module Fees
    class CreateReverseItemFees
      def initialize(line_item:, inventory_unit:)
        @line_item = line_item
        @inventory_unit = inventory_unit
      end

      def call
        return if line_item.platform_fee_total.zero?

        amount = inventory_unit.quantity * line_item.platform_fee_per_unit
        order = line_item.order

        fee = Spree::MarketplaceCommission.create!(
          order: order,
          feeable: line_item,
          label: Spree::MarketplaceCommission::REVERSE_ITEM_LABEL,
          rate: line_item.platform_fee_rate,
          amount: amount
        )

        line_item.platform_fee_reverse_total += fee.amount
        line_item.save!

        order.platform_fee_reverse_total += fee.amount
        order.save!

        fee
      end

      private

      attr_reader :line_item, :inventory_unit
    end
  end
end
