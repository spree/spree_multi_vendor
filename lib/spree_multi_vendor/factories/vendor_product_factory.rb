FactoryBot.define do
  factory :vendor_product, class: Spree::Product do
    sequence(:name)   { |n| "Product #{n}#{Kernel.rand(9999)}" }
    description       { generate(:random_description) }
    price             { 19.99 }
    cost_price        { 17.00 }
    sku               { generate(:sku) }
    available_on      { 1.year.ago }
    make_active_at    { 1.year.ago }
    deleted_at        { nil }
    shipping_category { |r| Spree::ShippingCategory.first || r.association(:shipping_category) }
    status            { 'active' }
    tax_category      { |r| Spree::TaxCategory.first || r.association(:tax_category) }
    vendor            { create(:vendor) }

    transient do
      price_currency { Spree::Store.default.default_currency }
    end

    before(:create) do |product|
      if product.stores.empty?
        default_store = Spree::Store.default.persisted? ? Spree::Store.default : nil
        store = default_store || create(:store)

        product.stores << [store]
      end
    end

    after(:create) do |product, evaluator|
      product.vendor.stock_locations.each do |stock_location|
        stock_location.propagate_variant(product.master) unless stock_location.stock_items.exists?(variant: product.master)
      end

      product_price = product.price_in(evaluator.price_currency)
      product_price.amount = evaluator.price
      product_price.save!
    end

    factory :vendor_product_in_stock do
      after :create do |product|
        product.master.stock_items.first.adjust_count_on_hand(10)
      end

      trait :without_backorder do
        after :create do |product|
          product.master.stock_items.update_all(backorderable: false)
        end
      end
    end
  end
end
