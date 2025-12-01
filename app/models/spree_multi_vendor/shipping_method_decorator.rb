module SpreeMultiVendor
  module ShippingMethodDecorator
    def self.prepended(base)
      base.after_save :touch_vendor, if: -> { vendor_id }
    end

    # connected methods are defined by vendors
    # and associated with a global shipping method
    def connected_method?
      vendor_id.present?
    end

    def touch_vendor
      vendor.touch
    end
  end
end

Spree::ShippingMethod.prepend(SpreeMultiVendor::ShippingMethodDecorator)
