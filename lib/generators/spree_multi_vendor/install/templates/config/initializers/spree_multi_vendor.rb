Rails.application.config.after_initialize do
  Spree.permissions.assign(:admin, SpreeMultiVendor::PermissionSets::SuperUser)
  Spree.permissions.assign(:vendor, SpreeMultiVendor::PermissionSets::VendorUser)
end
