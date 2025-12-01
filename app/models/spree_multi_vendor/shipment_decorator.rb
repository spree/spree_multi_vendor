module SpreeMultiVendor
  module ShipmentDecorator
    def self.prepended(base)
      base.before_validation :set_vendor_from_stock_location
      base.state_machine.event :cancel do
        transition to: :canceled, from: %i(pending ready shipped)
      end

      base.delegate :suborder?, to: :order
    end

    def refresh_rates(shipping_method_filter = ::Spree::ShippingMethod::DISPLAY_ON_FRONT_END)
      return shipping_rates if canceled?

      super
    end

    def items_marketplace_commission_total
      inventory_units.sum(Spree::Money.new(0, currency: currency), &:marketplace_commission_total)
    end

    def additional_tax_before_commission_total
      adjustments.tax.additional.sum(0.to_d) { |tax| (tax.amount_before_commission.presence || tax.amount).to_d }
    end

    protected

    def set_vendor_from_stock_location
      self.vendor ||= stock_location&.vendor || order&.vendor
    end
  end
end

Spree::Shipment.prepend(SpreeMultiVendor::ShipmentDecorator)
