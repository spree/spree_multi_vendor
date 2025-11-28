module SpreeMultiVendor
  module LineItemDecorator
    def self.prepended(base)
      base.include Spree::VendorConcern

      base.before_validation :set_vendor_from_product

      base.has_many :marketplace_commissions, as: :feeable, class_name: 'Spree::MarketplaceCommission', dependent: :destroy

      base.scope :platform_feeable, lambda {
                                      where("#{Spree::LineItem.table_name}.vendor_id IS NOT NULL AND #{Spree::LineItem.table_name}.pre_tax_amount > 0")
                                    }

      base.scope :with_product_external_id, ->(external_id) { joins(:product).merge(Spree::Product.by_external_id(external_id)) }
      base.scope :by_variant_external_id, ->(external_id) { joins(:variant).merge(Spree::Variant.with_deleted.by_external_id(external_id)) }

      base.money_methods :platform_fee_total, :platform_fee_per_unit, :platform_fee_discount
      base.money_methods :additional_tax_before_commission_total

      base.store_accessor :private_metadata, :platform_fee_discount

      base.delegate :suborder?, to: :order
    end

    def price_after_fees
      price - platform_fee_per_unit
    end

    def subtotal_after_fees
      price_after_fees * quantity
    end

    def total_after_fees
      total - platform_fee_total
    end

    def unit_discount_amount
      display_promo_total.amount_in_cents / quantity
    end

    def unit_tax_amount
      display_tax_total.amount_in_cents / quantity
    end

    def discounted_amount
      amount + taxable_adjustment_total
    end

    def discounted_amount_after_fees
      subtotal_after_fees + taxable_adjustment_total
    end

    def additional_tax_before_commission_total
      adjustments.tax.additional.sum(0.to_d) { |tax| (tax.amount_before_commission.presence || tax.amount).to_d }
    end

    def add_to_reimbursement(reimbursement, new_shipment, reimbursed_quantity)
      inventory_unit_scope = fully_shipped? ? inventory_units.shipped : inventory_units.available_to_split
      inventory_unit_scope = inventory_unit_scope.where(quantity: reimbursed_quantity..).order(quantity: :asc)
      inventory_unit = inventory_unit_scope.first

      return false unless inventory_unit.present?

      inventory_unit.extract_inventory!(new_quantity: reimbursed_quantity)
      inventory_unit.update!(shipment: new_shipment)

      return_item = inventory_unit.current_or_new_return_item
      return_item.accept!

      reimbursement.return_items << return_item

      true
    end

    protected

    def set_vendor_from_product
      self.vendor = product&.vendor if variant.present?
    end
  end
end

Spree::LineItem.prepend(SpreeMultiVendor::LineItemDecorator)
