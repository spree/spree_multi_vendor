module SpreeMultiVendor
  module PaymentDecorator
    def self.prepended(base)
      base.include Spree::VendorConcern
      base.before_validation :set_vendor_from_order
    end

    def set_vendor_from_order
      self.vendor = order.vendor
    end

    # We don't want to reimburse from gift card payments on vendor orders
    def can_credit?
      return false if vendor.present? && store_credit?

      super
    end
  end
end

Spree::Payment.prepend(SpreeMultiVendor::PaymentDecorator)
