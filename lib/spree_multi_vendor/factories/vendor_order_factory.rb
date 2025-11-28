FactoryBot.define do
  factory :splitted_order, parent: :completed_order_with_totals do
    state { 'splitted' }

    transient do
      payment_gateway { create(:credit_card_payment_method) }
    end

    after(:create) do |order, evaluator|
      create(:payment,
        order: order,
        amount: order.total,
        payment_method: evaluator.payment_gateway,
      )
    end
  end

  factory :placed_order, parent: :order_with_line_items do
    state { 'confirm' }
    completed_at { Time.current }

    after(:create) do |order, evaluator|
      create(
        :payment,
        amount: order.total,
        order: order,
        payment_method: evaluator.payment_gateway
      )
    end
  end

  factory :placed_order_with_vendor_items, parent: :order do
    state { 'confirm' }
    completed_at { Time.current }

    bill_address
    ship_address

    transient do
      line_items_count  { 1 }
      shipment_cost     { 100 }
      vendor            { create(:approved_vendor) }
      payment_gateway   { create(:credit_card_payment_method) }
    end

    after(:create) do |order, evaluator|
      create_list(
        :vendor_line_item,
        evaluator.line_items_count,
        order: order,
        price: evaluator.line_items_price,
        vendor: evaluator.vendor,
        platform_fee_total: evaluator.line_items_price * 0.2
      )

      order.line_items.reload

      create(:vendor_shipment, order: order, cost: evaluator.shipment_cost, vendor: evaluator.vendor)
      order.shipments.reload

      order.update_with_updater!

      create(
        :payment,
        amount: order.total,
        order: order,
        payment_method: evaluator.payment_gateway
      )
    end
  end

  factory :vendor_order, parent: :order do
    parent { create(:order) }
    vendor { create(:approved_vendor) }
  end

  factory :vendor_order_with_totals, class: Spree::Order, parent: :order do
    parent { create(:order) }

    transient do
      source { nil }
    end

    after(:create) do |order, evaluator|
      create(:vendor_line_item,
             order: order,
             price: evaluator.line_items_price,
             vendor: order.vendor)

      order.line_items.reload # to ensure order.line_items is accessible after
    end
  end

  factory :vendor_order_with_line_items, class: Spree::Order, parent: :order do
    bill_address
    ship_address
    vendor { create(:approved_vendor) }
    parent { create(:order) }

    transient do
      line_items_count       { 1 }
      without_line_items     { false }
      shipment_cost          { 100 }
      shipping_method_filter { Spree::ShippingMethod::DISPLAY_ON_FRONT_END }
    end

    after(:create) do |order, evaluator|
      unless evaluator.without_line_items
        create_list(:vendor_line_item, evaluator.line_items_count,
                    order: order,
                    price: evaluator.line_items_price,
                    vendor: order.vendor,
                    platform_fee_total: evaluator.line_items_price * 0.2)

        order.line_items.reload
      end

      create(:vendor_shipment, order: order, cost: evaluator.shipment_cost, vendor: order.vendor)
      order.shipments.reload

      order.update_with_updater!
    end

    factory :vendor_completed_order_with_totals do
      state { 'complete' }

      after(:create) do |order, evaluator|
        order.refresh_shipment_rates(evaluator.shipping_method_filter)
        order.update_column(:completed_at, Time.current)
      end

      factory :vendor_completed_order_with_pending_payment do
        after(:create) do |order|
          payment_method = if order.parent.present? && order.parent.payments.first&.payment_method
                             order.parent.payments.first.payment_method
                           else
                             SpreeStripe::Gateway.first || create(:credit_card_payment_method, stores: [order.store])
                           end

          create(:payment,
                 amount: order.total,
                 order: order,
                 payment_method: payment_method)
        end
      end

      factory :vendor_completed_order_with_store_credit_payment do
        after(:create) do |order|
          store_credit = create(:store_credit, amount: order.total, store: order.store, user: order.user)
          payment_method = create(:store_credit_payment_method, stores: [order.store])

          create(:store_credit_payment, amount: order.total, order: order, source: store_credit, payment_method: payment_method)
        end
      end

      factory :vendor_order_ready_to_ship do
        payment_state  { 'paid' }
        shipment_state { 'ready' }

        transient do
          payment_gateway { nil }
          with_payment { true }
        end

        after(:create) do |order, evaluator|
          payment_method = if order.parent.present? && order.parent.payments.first&.payment_method
                             order.parent.payments.first.payment_method
                           else
                             evaluator.payment_gateway || order.store.payment_methods.where.not(type: 'Spree::PaymentMethod::StoreCredit').first || create(:credit_card_payment_method, stores: [order.store])
                           end

          if evaluator.with_payment
            create(
              :payment,
              amount: order.total,
              order: order,
              state: 'completed',
              payment_method: payment_method
            )
          end

          order.shipments.each do |shipment|
            shipment.inventory_units.update_all state: 'on_hand'
            shipment.update_column('state', 'ready')
          end
          order.reload
        end

        factory :vendor_shipped_order do
          after(:create) do |order|
            order.shipments.each do |shipment|
              shipment.inventory_units.update_all state: 'shipped'
              shipment.update_column('state', 'shipped')
            end
            order.update_column('shipment_state', 'shipped')
            order.reload
          end
        end
      end
    end
  end
end
