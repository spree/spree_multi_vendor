module Spree
  module Calculators::Returns
    class PlatformRefundAmount < ReturnsCalculator
      def compute(return_item)
        return 0.to_d if return_item.exchange_requested?

        line_item = return_item.line_item
        promo_per_item = line_item.promo_total.abs / line_item.quantity
        included_tax_per_item = line_item.included_tax_total / line_item.quantity
        refund_amount_per_item = line_item.price - promo_per_item - included_tax_per_item - line_item.platform_fee_per_unit

        return_item.return_quantity * refund_amount_per_item
      end
    end
  end
end
