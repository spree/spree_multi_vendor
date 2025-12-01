module SpreeMultiVendor
  module Fees
    class CalculateItemFee
      prepend Spree::ServiceModule::Base

      def call(item:, rate: nil)
        rate ||= item.product.platform_fee.presence || item.product.vendor&.platform_fee
        return failure(item: item, rate: rate) if rate.nil? || rate.zero?

        promo_per_unit = item.promo_total.abs / item.quantity
        store_credit_per_unit = calculate_store_credit_per_item(item)

        feeable_amount = item.price - promo_per_unit - store_credit_per_unit
        fee_per_unit = (feeable_amount * rate / 100).round(2, BigDecimal::ROUND_HALF_UP)
        fee_total = fee_per_unit * item.quantity

        success(
          rate: rate,
          fee_per_unit: fee_per_unit,
          fee_total: fee_total,
          store_credit_per_unit: store_credit_per_unit
        )
      end

      private

      def calculate_store_credit_per_item(item)
        order = item.order.parent || item.order
        return 0 if order.nil? || order.total_applied_store_credit.zero?

        ((item.price / order.item_total) * order.total_applied_store_credit).round(2, BigDecimal::ROUND_HALF_UP)
      end
    end
  end
end
