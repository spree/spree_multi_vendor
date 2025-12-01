module SpreeMultiVendor
  module Adjustable
    module AdjustmentsUpdaterDecorator
      private

      def persist_totals(totals)
        attributes = totals

        attributes[:adjustment_total] = totals[:non_taxable_adjustment_total] + totals[:taxable_adjustment_total]
        attributes[:adjustment_total] += totals[:additional_tax_total] unless @adjustable.suborder?

        attributes[:updated_at] = Time.current
        @adjustable.update_columns(totals)
      end
    end
  end
end

Spree::Adjustable::AdjustmentsUpdater.prepend(SpreeMultiVendor::Adjustable::AdjustmentsUpdaterDecorator)
