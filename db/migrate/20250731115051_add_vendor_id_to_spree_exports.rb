class AddVendorIdToSpreeExports < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:spree_exports, :vendor_id)
      add_reference :spree_exports, :vendor
    end
  end
end
