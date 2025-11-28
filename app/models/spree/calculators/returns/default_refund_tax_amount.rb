module Spree
  module Calculators::Returns
    class DefaultRefundTaxAmount < ReturnsCalculator
      def compute(return_item, type:)
        return 0.to_d if return_item.exchange_requested?

        line_item = return_item.line_item

        case type
        when :additional
          calculate_tax_amount(return_item, line_item.additional_tax_total)
        when :included
          calculate_tax_amount(return_item, line_item.included_tax_total)
        end
      end

      private

      def calculate_tax_amount(return_item, line_item_tax_amount)
        line_item = return_item.line_item
        tax_amount_per_unit = line_item_tax_amount / line_item.quantity

        return_item.return_quantity * tax_amount_per_unit
      end
    end
  end
end
