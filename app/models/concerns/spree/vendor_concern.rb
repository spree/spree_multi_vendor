module Spree
  module VendorConcern
    extend ActiveSupport::Concern

    included do
      belongs_to :vendor, -> { with_deleted }, class_name: 'Spree::Vendor', touch: false, optional: true

      scope :with_vendor, ->(vendor_id) { where(vendor_id: vendor_id) }
      scope :has_vendor, -> { where.not(vendor_id: nil) }
      scope :without_vendor, -> { where(vendor_id: nil) }
    end

    def has_vendor?(vendor)
      self.vendor == vendor
    end
  end
end
