module SpreeMultiVendor
  module AdminUserDecorator
    def self.prepended(base)
      base.has_many :vendors, through: :role_users, source: :resource, source_type: 'Spree::Vendor'
    end
  end
end

if Spree.admin_user_class.present?
  Spree.admin_user_class.prepend(SpreeMultiVendor::AdminUserDecorator) unless Spree.admin_user_class.include?(SpreeMultiVendor::AdminUserDecorator)
end
