module SpreeMultiVendor
  module InventoryUnitDecorator
    def self.prepended(base)
      base.scope :available_to_split, lambda {
                                        joins(:shipment).
                                          where(
                                            state: 'on_hand',
                                            Spree::Shipment.table_name => { external_id: nil }
                                          ).
                                          where.not(
                                            Spree::Shipment.table_name => { state: [:canceled, :shipped] }
                                          )
                                      }
    end

    # def marketplace_commission_additional_tax
    #   subtotal = marketplace_commission_subtotal
    #   item_taxes = line_item.adjustments.additional.tax
    #   tax_rates = item_taxes.map(&:source)

    #   tax_rates.sum(Spree::Money.new(0, currency: line_item.currency)) { |tax_rate| subtotal * tax_rate.amount }
    # end

    def marketplace_commission_total
      (line_item.display_platform_fee_per_unit * quantity) - line_item.display_platform_fee_discount
    end

    def extract_inventory!(new_quantity:)
      remaining_quantity = quantity - new_quantity
      split_inventory!(remaining_quantity) if remaining_quantity.positive?
    end
  end
end

Spree::InventoryUnit.prepend(SpreeMultiVendor::InventoryUnitDecorator) unless Spree::InventoryUnit.include?(SpreeMultiVendor::InventoryUnitDecorator)
