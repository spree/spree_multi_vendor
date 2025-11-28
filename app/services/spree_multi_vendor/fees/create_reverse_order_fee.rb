module SpreeMultiVendor
  module Fees
    class CreateReverseOrderFee
      def initialize(order:, refunded_amount:)
        @order = order
        @refunded_amount = refunded_amount
      end

      def call
        refunded_rate = refunded_amount / (order.total - order.ship_total)

        reverse_platform_fee_amount = (refunded_rate * order.platform_fee_total.abs).round(2)
        remaining_platform_fee_amount = [order.platform_fee_total.abs - order.platform_fee_reverse_total.abs, 0.to_d].max

        reverse_platform_fee_amount = [reverse_platform_fee_amount, remaining_platform_fee_amount].min

        return if reverse_platform_fee_amount.zero?

        fee = Spree::MarketplaceCommission.create!(
          feeable: order,
          order: order,
          amount: reverse_platform_fee_amount,
          label: Spree::MarketplaceCommission::REVERSE_ORDER_LABEL
        )

        order.platform_fee_reverse_total += fee.amount
        order.save!

        fee
      end

      private

      attr_reader :order, :refunded_amount
    end
  end
end
