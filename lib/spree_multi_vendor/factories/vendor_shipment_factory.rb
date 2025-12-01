FactoryBot.define do
  factory :vendor_shipment, class: Spree::Shipment do
    tracking { 'U10000' }
    cost     { 100.00 }
    state    { 'pending' }
    order
    stock_location { vendor.stock_locations.first }
    vendor

    transient do
      shipping_method_attributes { {} }
      map_inventory_units { true }
    end

    after(:create) do |shipment, evaluator|
      shipping_method_name = evaluator.shipping_method_attributes[:name]
      shipping_method_scope = { name: shipping_method_name } if shipping_method_name.present?

      shipping_method = shipment.vendor.shipping_methods.where(shipping_method_scope).first ||
                        create(:shipping_method, vendor: shipment.vendor, **evaluator.shipping_method_attributes)

      shipment.add_shipping_method(shipping_method, true)

      if evaluator.map_inventory_units
        shipment.order.line_items.map do |line_item|
          shipment.inventory_units.create(
            order_id: shipment.order_id,
            variant_id: line_item.variant_id,
            line_item_id: line_item.id,
            quantity: line_item.quantity
          )
        end
      end
    end
  end
end
