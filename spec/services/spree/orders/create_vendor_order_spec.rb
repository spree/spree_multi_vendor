require 'spec_helper'

RSpec.describe Spree::Orders::CreateVendorOrder do
  let(:store) { Spree::Store.default }
  let!(:default_stock_location) { create(:stock_location, name: 'default', default: true) }
  let(:user) { create(:user) }
  let(:parent_order) do
    create(:order, store: store, currency: 'USD', user: user,
                   special_instructions: 'Hi there', last_ip_address: '127.0.0.1',
                   bill_address: create(:address, user: user), ship_address: create(:address, user: user))
  end
  let(:vendor_order) { subject.value }

  let(:vendor) { create(:approved_vendor, platform_fee: 10.to_d) }
  let(:vendor_2) { create(:approved_vendor) }

  let(:product) { create(:vendor_product_in_stock, vendor: vendor, price: 90.0) }
  let(:product_2) { create(:vendor_product_in_stock, vendor: vendor, price: 49.0) }
  let(:product_3) { create(:vendor_product_in_stock, vendor: vendor_2, price: 100.0) }
  let(:variant) { product.default_variant }
  let(:variant_2) { product_2.default_variant }
  let(:variant_3) { product_3.default_variant }

  let!(:line_item) { create(:line_item, order: parent_order, product: product, price: product.price) }
  let!(:line_item_2) { create(:line_item, order: parent_order, product: product_2, price: product_2.price) }
  let!(:line_item_3) { create(:line_item, order: parent_order, product: product_3, price: product_3.price) }

  let!(:payment) { create(:payment, order: parent_order, amount: parent_order.total) }

  subject { described_class.call(order: parent_order, vendor: vendor, index: 2) }

  context 'dynamic shipping' do
    let!(:shipment) { create(:shipment, order: parent_order, stock_location: vendor.stock_locations.first, cost: 5.0) }
    let!(:shipment_2) { create(:shipment, order: parent_order, stock_location: vendor_2.stock_locations.first, cost: 5.0) }

    let!(:shipment_adjustments) { create_list(:tax_adjustment, 2, adjustable: shipment, order: parent_order, amount: 10.0) }
    let!(:shipment_2_adjustments) { create(:tax_adjustment, adjustable: shipment_2, order: parent_order) }

    before do
      parent_order.update_with_updater!
      parent_order.update(
        completed_at: '2020-11-01 10:00:00',
        state: 'complete',
        payment_state: 'balance_due',
        shipment_state: 'pending',
        confirmation_delivered: true
      )
    end

    describe 'new vendor order' do
      it { expect { subject }.to change { Spree::Order.has_vendor.count }.by(1) }

      it 'creates a new vendor order' do
        expect(vendor_order).to have_attributes(
          number: "#{parent_order.number}-2",
          email: user.email,
          user_id: user.id,
          store_id: store.id,
          special_instructions: 'Hi there',
          last_ip_address: '127.0.0.1',
          state: 'complete',
          payment_state: 'balance_due',
          shipment_state: 'pending',
          completed_at: parent_order.completed_at,
          confirmation_delivered: true,
          item_count: 2,
          item_total: 139.to_d,
          platform_fee_total: -13.9.to_d, # vendor fee is 10% of item total
          shipment_total: 5.to_d,
          adjustment_total: 0.to_d,
          additional_tax_total: 1.to_d,
          total: 144.to_d, # we don't include additional tax in vendor order total
          vendor_id: vendor.id,
          parent_id: parent_order.id,
          currency: parent_order.currency
        )
      end

      it 'calculates platform fee total correctly' do
        expect(vendor_order.platform_fee_total).to eq(-0.1 * vendor_order.item_total)
      end

      it 'calculates total correctly' do
        expect(vendor_order.total).to eq(
          vendor_order.item_total + vendor_order.shipment_total + vendor_order.adjustment_total
        )
      end

      it 'updates vendor cache' do
        subject
        expect(vendor.reload.sales_total).to  eq vendor.orders.complete.sum(:total)
        expect(vendor.commission_total).to  eq vendor.orders.complete.sum(:platform_fee_total).abs
      end

      it 'cannot create the same order twice' do
        expect { subject }.to change { Spree::Order.has_vendor.count }.by(1)
        expect { subject }.not_to change { Spree::Order.has_vendor.count }
      end

      context 'if default store currency is different than parent order currency' do
        it "sets vendor's order currency to parent_order's currency" do
          allow_any_instance_of(Spree::Store).to receive(:default_currency).and_return('EUR')

          subject
          expect(vendor_order.currency).to eq 'USD'
        end
      end
    end

    describe 'moves vendor line items to vendor_order' do
      it { expect { subject }.not_to change { Spree::LineItem.count } }
      it { expect { subject }.not_to change { Spree::InventoryUnit.count } }
      it { expect { subject }.not_to change { Spree::Adjustment.where.not(source: nil).count } }

      it { expect { subject }.to change { parent_order.line_items.count }.from(3).to(1) }

      it 'changes order for line items' do
        expect(line_item.order).to eq(parent_order)
        expect(line_item_2.order).to eq(parent_order)
        expect(line_item_3.order).to eq(parent_order)
        subject
        expect(line_item.reload.order).to eq(vendor_order)
        expect(line_item_2.reload.order).to eq(vendor_order)
        expect(line_item_3.reload.order).to eq(parent_order)
      end
    end

    describe 'assigns addresses to the new order' do
      context 'guest order' do
        before do
          parent_order.update!(user: nil, email: 'new@email.com')
          parent_order.bill_address.update!(user: nil)
          parent_order.ship_address.update!(user: nil)
        end

        it 'assigns the same addresses' do
          expect(vendor_order.bill_address).to eq(parent_order.bill_address.reload)
          expect(vendor_order.ship_address).to eq(parent_order.ship_address.reload)
        end
        it { expect { subject }.not_to change(Spree::Address, :count) }
      end

      context 'signed in user' do
        it 'assigns the same addresses' do
          expect(vendor_order.bill_address).to eq(parent_order.bill_address.reload)
          expect(vendor_order.ship_address).to eq(parent_order.ship_address.reload)
        end
        it { expect { subject }.not_to change(Spree::Address, :count) }
      end
    end

    describe 'create_payments' do
      it 'creates vendor payment' do
        subject

        vendor_payment = vendor_order.payments.last

        expect(vendor_order.payments.count).to eq(1)
        expect(vendor_payment.amount).to eq vendor_order.total
        expect(vendor_payment.source).to eq payment.source
        expect(vendor_payment.response_code).to eq payment.response_code
        expect(vendor_payment.payment_method).to eq payment.payment_method
        expect(vendor_payment.state).to eq 'completed'
      end
    end

    describe 'create_store_credit_payments' do
      let(:store_credit) { create(:store_credit, amount: store_credit_amount, user: parent_order.user) }
      let(:store_credit_payment) { create(:store_credit_payment, source: store_credit, order: parent_order, amount: store_credit_amount, state: 'completed') }

      context 'when order is partially covered by store credit' do
        let(:store_credit_amount) { 20 }

        before do
          store_credit_payment
        end

        it 'creates a store credit payment with the proportional amount for a vendor order' do
          subject

          vendor_payment = vendor_order.payments.store_credits.last

          expect(vendor_order.payments.store_credits.count).to eq(1)
          expect(vendor_payment.vendor).to eq(vendor)
          expect(vendor_payment.number).to eq("#{store_credit_payment.number}-2")
          expect(vendor_payment.amount).to eq(11.63)
          expect(vendor_payment.source).to eq(store_credit_payment.source)
          expect(vendor_payment.response_code).to eq(store_credit_payment.response_code)
          expect(vendor_payment.payment_method).to eq(store_credit_payment.payment_method)
          expect(vendor_payment.state).to eq('completed')
        end

        it 'creates payment for the remaining amount' do
          subject

          cc_payment = vendor_order.payments.not_store_credits.last
          store_credit_payment = vendor_order.payments.store_credits.last

          expect(vendor_order.payments.not_store_credits.count).to eq(1)
          expect(cc_payment.amount).to eq(vendor_order.item_total + vendor_order.ship_total - store_credit_payment.amount)
          expect(cc_payment.state).to eq('completed')
        end
      end

      context 'when order is fully covered by store credit' do
        let(:store_credit_amount) { parent_order.total }

        before do
          payment.destroy
          parent_order.reload

          store_credit_payment
        end

        it 'creates a store credit payment using proportional total split' do
          subject

          vendor_payment = vendor_order.payments.store_credits.last

          expect(vendor_order.payments.store_credits.count).to eq(1)
          expect(vendor_payment.number).to eq("#{store_credit_payment.number}-2")
          expect(vendor_payment.amount).to eq(144)
          expect(vendor_payment.source).to eq(store_credit_payment.source)
          expect(vendor_payment.payment_method).to eq(store_credit_payment.payment_method)
          expect(vendor_payment.state).to eq('completed')
        end

        it 'does not create other payments' do
          subject
          expect(vendor_order.payments.not_store_credits.count).to eq(0)
        end
      end
    end

    describe 'moves vendor shipments to vendor_order' do
      it 'changes order for shipments and shipment adjustments' do
        expect(parent_order.shipments.count).to eq(2)
        expect(parent_order.shipment_adjustments.count).to eq(3)

        subject

        expect(vendor_order.reload.shipments.count).to eq(1)
        expect(vendor_order.shipment_adjustments.count).to eq(2)

        expect(parent_order.shipments.count).to eq(1)
        expect(parent_order.shipment_adjustments.count).to eq(1)
      end

      it 'assigns addresse from order to the new shipment' do
        subject

        expect(vendor_order.reload.shipments.pluck(:address_id).uniq).to eq([vendor_order.ship_address_id])
      end
    end

    describe 'create_marketplace_commissions' do
      it 'triggers SpreeMultiVendor::Fees::CreateAllItemsFees' do
        expect(SpreeMultiVendor::Fees::CreateAllItemsFees).to receive_message_chain(:new, :call).and_return([])

        subject
      end

      context 'when order is fully covered by store credit' do
        before do
          payment.destroy
          parent_order.reload

          store_credit = create(:store_credit, amount: parent_order.total, user: parent_order.user)
          create(:store_credit_payment, source: store_credit, order: parent_order, amount: parent_order.total, state: 'completed')
        end

        it 'does not create marketplace commissions' do
          expect(SpreeMultiVendor::Fees::CreateAllItemsFees).not_to receive(:new)
          subject
        end

        it 'vendor order has zero platform fee total' do
          subject
          expect(vendor_order.platform_fee_total).to eq(0)
        end
      end
    end
  end

  xcontext 'with commission discount' do
    let(:promotion) { create(:promotion, kind: :automatic) }
    let(:vendor) { create(:approved_vendor, platform_fee: 50.0) }
    let(:vendor_2) { create(:approved_vendor, platform_fee: 20.0) }
    let(:vendor_2_order) { described_class.call(order: parent_order, vendor: vendor_2, index: 1).value }

    before do
      Spree::Promotion::Actions::CreateAdjustment.create!(calculator: calculator, promotion: promotion)
      promotion.activate(order: parent_order.reload)
    end

    context 'with amount calculator' do
      let(:calculator) do
        calculator = Spree::Calculator::FlatRate.new
        calculator.preferred_amount = 50
        calculator.preferred_currency = 'USD'
        calculator
      end

      it 'should be counted as one usage' do
        expect(promotion.reload.credits_count).to eq(1)
      end

      it 'calculates platform fee for vendor orders correctly' do
        expect(parent_order.promo_total).to eq(-50)

        expect(vendor_order.reload.platform_fee_total).to eq(-19.5)
        expect(vendor_2_order.reload.platform_fee_total).to eq(-20)

        expect(vendor_order.total.to_f).to eq(69.5) # 135 * 0.5
        expect(vendor_2_order.total).to eq(80) # 100 * 0.8

        expect(vendor_order.item_total).to eq(139)
        expect(vendor_2_order.item_total).to eq(100)

        expect(vendor_order.line_items.first.platform_fee_total).to eq(0.0)
        expect(vendor_order.line_items.first.private_metadata[:platform_fee_discount].to_f).to eq(45)
        expect(vendor_order.line_items.second.platform_fee_total).to eq(19.5)
        expect(vendor_order.line_items.second.private_metadata[:platform_fee_discount].to_f).to eq(5.0)
        expect(vendor_2_order.line_items.first.platform_fee_total).to eq(20)
        expect(vendor_2_order.line_items.first.private_metadata[:platform_fee_discount].to_f).to eq(0.0)
      end
    end

    xcontext 'with percent calculator' do
      let(:calculator) do
        calculator = Spree::Calculator::FlatPercentItemTotal.new
        calculator.preferred_flat_percent = 10
        calculator
      end

      it 'should be counted as one usage' do
        expect(promotion.reload.credits_count).to eq(1)
      end

      it 'calculates platform fee for vendor orders correctly' do
        expect(parent_order.promo_total).to eq(-23.9) # 10% of 239

        expect(vendor_order.reload.platform_fee_total).to eq(-45.6)
        expect(vendor_2_order.reload.platform_fee_total).to eq(-20)

        expect(vendor_order.total.to_f).to eq(69.5)
        expect(vendor_2_order.total).to eq(80)

        expect(vendor_order.item_total).to eq(139)
        expect(vendor_2_order.item_total).to eq(100)

        expect(vendor_order.line_items.first.platform_fee_total).to eq(21.1)
        expect(vendor_order.line_items.first.private_metadata[:platform_fee_discount].to_f).to eq(23.9)
        expect(vendor_order.line_items.second.platform_fee_total).to eq(24.5)
        expect(vendor_order.line_items.second.private_metadata[:platform_fee_discount].to_f).to eq(0.0)
        expect(vendor_2_order.line_items.first.platform_fee_total).to eq(20)
        expect(vendor_2_order.line_items.first.private_metadata[:platform_fee_discount].to_f).to eq(0.0)
      end
    end
  end
end
