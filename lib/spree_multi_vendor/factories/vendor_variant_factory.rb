FactoryBot.define do
  factory :vendor_variant, class: Spree::Variant do
    price           { 19.99 }
    cost_price      { 17.00 }
    sku             { generate(:sku) }
    weight          { generate(:random_float) }
    height          { generate(:random_float) }
    width           { generate(:random_float) }
    depth           { generate(:random_float) }
    is_master       { 0 }
    track_inventory { true }

    product       { |p| p.association(:vendor_product, stores: [create(:store)]) }
    option_values { [create(:option_value)] }

    after(:create) do |variant|
      variant.product.vendor.stock_locations.each do |stock_location|
        stock_location.propagate_variant(variant)
      end
    end

    factory :vendor_variant_in_stock do
      transient do
        stock_count { 10 }
      end

      after(:create) do |variant, evaluator|
        variant.stock_items.first.adjust_count_on_hand(evaluator.stock_count)
      end
    end
  end
end
