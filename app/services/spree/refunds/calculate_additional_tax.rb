module Spree
  module Refunds
    class CalculateAdditionalTax
      prepend ServiceModule::Base

      def call(refund:)
        additional_tax = calculate_additional_tax(refund)
        success(additional_tax)
      end

      private

      def calculate_additional_tax(refund)
        currency = refund.currency

        reimbursement = refund.reimbursement
        order = refund.order
        zero_money = Spree::Money.new(0, currency: currency)

        return zero_money if order.parent_order?

        if reimbursement
          return Spree::Money.new(0, currency: currency) if reimbursement.custom_total?

          return_items = refund.return_items.includes(inventory_unit: :line_item)
          return_items.sum(zero_money) do |return_item|
            line_item = return_item.inventory_unit.line_item
            quantity = return_item.inventory_unit.quantity
            max_quantity = line_item.quantity
            total_tax = line_item.additional_tax_total

            Spree::Money.new((quantity * total_tax / max_quantity.to_d).round(2, BigDecimal::ROUND_HALF_UP))
          end
        else
          line_item_tax = order.line_items.sum(zero_money, &:display_additional_tax_total)
          shipment_tax = order.shipments.sum(zero_money, &:display_additional_tax_total)

          line_item_tax + shipment_tax
        end
      end
    end
  end
end
