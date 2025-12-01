module SpreeMultiVendor
  module PolicyDecorator
    def self.prepended(base)
      base.scope :with_vendor, ->(vendor_id) { where(owner_type: 'Spree::Vendor', owner_id: vendor_id) }
      base.scope :has_vendor, -> { where.not(owner_type: 'Spree::Vendor') }
      base.scope :without_vendor, -> { where.not(owner_type: 'Spree::Vendor') }
    end
  end

  ::Spree::Policy.prepend(SpreeMultiVendor::PolicyDecorator) unless Spree::Policy.include?(SpreeMultiVendor::PolicyDecorator)
end
