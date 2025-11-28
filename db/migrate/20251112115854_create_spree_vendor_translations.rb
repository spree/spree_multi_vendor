class CreateSpreeVendorTranslations < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_vendor_translations do |t|
      t.string :locale, null: false
      t.references :spree_vendor, null: false

      t.timestamps
    end

    add_index :spree_vendor_translations, %i[spree_vendor_id locale], unique: true
  end
end
