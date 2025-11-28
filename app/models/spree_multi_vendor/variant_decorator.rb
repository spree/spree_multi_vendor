module SpreeMultiVendor
  module VariantDecorator
    def self.prepended(base)
      base.has_one :vendor, through: :product, class_name: 'Spree::Vendor'

      base.scope :with_vendor, ->(vendor) { joins(:product).merge(Spree::Product.with_vendor(vendor)) }
    end

    def weight_unit
      attributes['weight_unit'] || product.vendor&.weight_unit || Spree::Store.default.preferred_weight_unit
    end

    # we need to disable SKU validation for multi-vendor
    def disable_sku_validation?
      true
    end

    private

    def ensure_not_in_complete_orders
      return if external_id.present?

      super
    end
  end
end

Spree::Variant.prepend(SpreeMultiVendor::VariantDecorator)
