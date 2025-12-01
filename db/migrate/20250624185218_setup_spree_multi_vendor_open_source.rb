class SetupSpreeMultiVendorOpenSource < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_vendors, if_not_exists: true do |t|
      t.string :name, index: true, null: false
      t.string :original_name, index: true
      t.string :state, index: true, null: false

      if t.respond_to? :jsonb
        t.jsonb :public_metadata
        t.jsonb :private_metadata
      else
        t.json :public_metadata
        t.json :private_metadata
      end

      t.integer :products_count, default: 0, null: false, index: true
      t.decimal :sales_total, precision: 8, scale: 2, default: "0.0", null: false, index: true
      t.decimal :commission_total, precision: 8, scale: 2, default: "0.0", null: false, index: true

      t.bigint :returns_address_id, index: true
      t.string :contact_person_email, index: true
      t.bigint :invited_by_id, index: true
      t.bigint :billing_address_id, index: true
      t.string :billing_email

      t.text :preferences
      t.decimal :platform_fee, precision: 10, scale: 2, default: 30.0, null: false
      t.string :payouts_schedule_interval, default: 'monthly', null: false

      t.datetime :deleted_at, index: true
      t.timestamps
    end

    create_table :spree_external_categories, if_not_exists: true do |t|
      t.string :name, null: false, index: true
      t.bigint :taxon_id, index: true
      t.bigint :vendor_id, index: true

      t.string :external_id, index: true
      t.string :type, null: false, index: true

      t.datetime :deleted_at, index: true
      t.timestamps
    end

    create_table :spree_platform_fees, if_not_exists: true do |t|
      t.bigint :order_id, null: false, index: true
      t.string :feeable_type, null: false
      t.bigint :feeable_id, null: false
      t.string :label, index: true
      t.boolean :active, default: true, index: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.decimal :rate, precision: 5, scale: 2

      t.timestamps
    end

    add_index :spree_platform_fees, %w[feeable_id feeable_type], name: "index_spree_platform_fees_on_feeable_id_and_feeable_type", if_not_exists: true

    %w[
      spree_line_items
      spree_orders
      spree_payments
      spree_products
      spree_reports
      spree_shipments
      spree_shipping_methods
      spree_stock_locations
      spree_webhooks_subscribers
    ].each do |table|
      if table_exists?(table)
        add_column table, :vendor_id, :bigint, if_not_exists: true
        add_index table, :vendor_id, if_not_exists: true
      end
    end

    %w[
      spree_product_properties
      spree_products
      spree_shipments
      spree_shipping_methods
      spree_stock_items
      spree_variants
      spree_assets
      spree_orders
      spree_line_items
    ].each do |table|
      if table_exists?(table)
        add_column table, :external_id, :string, if_not_exists: true
        add_index table, :external_id, if_not_exists: true
      end
    end

    add_column :spree_products, :platform_fee, :decimal, precision: 10, scale: 2, null: true, if_not_exists: true

    add_column :spree_orders, :platform_fee_total, :decimal, precision: 10, scale: 2, default: "0.0", if_not_exists: true
    add_column :spree_orders, :parent_id, :bigint, if_not_exists: true
    add_index :spree_orders, :parent_id, if_not_exists: true
    add_column :spree_orders, :platform_fee_reverse_total, :decimal, precision: 10, scale: 2, default: "0.0", if_not_exists: true

    add_column :spree_line_items, :platform_fee_total, :decimal, precision: 10, scale: 2, default: "0.0", if_not_exists: true
    add_column :spree_line_items, :platform_fee_rate, :decimal, precision: 5, scale: 2, if_not_exists: true
    add_column :spree_line_items, :platform_fee_per_unit, :decimal, precision: 10, scale: 2, default: "0.0", if_not_exists: true
    add_column :spree_line_items, :platform_fee_reverse_total, :decimal, precision: 10, scale: 2, default: "0.0", if_not_exists: true
  end
end
