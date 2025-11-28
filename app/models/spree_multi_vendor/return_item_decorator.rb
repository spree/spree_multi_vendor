module SpreeMultiVendor
  module ReturnItemDecorator
    def self.prepended(base)
      base.class_attribute :refund_tax_amount_calculator
      base.refund_tax_amount_calculator = ::Spree::Calculators::Returns::DefaultRefundTaxAmount

      base.before_create :calculate_refund_tax_amounts
      base.before_save :set_tax_amounts_to_zero, if: :exchange_requested?

      base.money_methods :marketplace_commission_total, :marketplace_total
      base.money_methods :additional_tax_total, :additional_tax_before_commission_total

      base.store_accessor :private_metadata, :additional_tax
      base.money_methods :amount_before_commission
    end

    def marketplace_commission_total
      return_quantity * line_item.platform_fee_per_unit
    end

    def marketplace_total
      pre_tax_amount + marketplace_commission_total
    end

    def additional_tax_before_commission_total
      item_taxes = line_item.adjustments.additional.tax
      tax_rates = item_taxes.map(&:source)
      tax_rates.sum(0.to_d) { |tax_rate| line_item.price * return_quantity * tax_rate.amount }
    end

    private

    def calculate_refund_tax_amounts
      calculator = refund_tax_amount_calculator.new

      self.additional_tax_total = calculator.compute(self, type: :additional)
      self.included_tax_total = calculator.compute(self, type: :included)
    end

    def set_tax_amounts_to_zero
      self.additional_tax_total = 0.to_d
      self.included_tax_total = 0.to_d
    end
  end
end

Spree::ReturnItem.prepend(SpreeMultiVendor::ReturnItemDecorator) unless Spree::ReturnItem.included_modules.include?(SpreeMultiVendor::ReturnItemDecorator)
