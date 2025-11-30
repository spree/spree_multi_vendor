require 'spec_helper'

class FakeCalculator < Spree::Calculator
  def compute(_computable)
    5
  end
end

RSpec.describe Spree::Order, type: :model do
  before do
    allow(Spree::LegacyUser).to receive_messages(current: create(:user))
  end

  let(:user) { create(:user) }
  let(:store) { Spree::Store.default }
  let(:order) { create(:order, user: user, store: store) }

  describe 'vendors association' do
    let(:vendor) { create(:vendor) }
    let(:product) { create(:product_in_stock, vendor: vendor, price: 100.0) }
    let(:variant) { product.default_variant }
    let!(:line_item) { create_list(:line_item, 2, order: order, product: product, price: product.price) }

    it do
      # Regression test for ActiveRecord::StatementInvalid: PG::InvalidColumnReference: ERROR:  for SELECT DISTINCT, ORDER BY expressions must appear in select list
      expect { order.vendors }.not_to raise_error(ActiveRecord::StatementInvalid)
      expect(order.vendors.to_a).to match_array([vendor])
    end
  end

  describe 'callbacks' do
    describe 'after_complete' do
      let(:order) { create(:order_with_totals, state: :confirm, total: 100) }

      describe '#split_order' do
        subject(:complete_order) { order.next! }

        before do
          allow(order).to receive(:process_payments!)
        end

        context 'for an order with 1st party products' do
          let(:order) { create(:placed_order) }

          it 'skips splitting the order after completing it' do
            expect { complete_order }.to_not have_enqueued_job(SpreeMultiVendor::Orders::SplitByVendorJob)
          end
        end

        context 'for an order with 3rd party products' do
          let(:order) { create(:placed_order_with_vendor_items) }

          it 'splits order after completing it' do
            expect { complete_order }.to have_enqueued_job(SpreeMultiVendor::Orders::SplitByVendorJob).with(order.id)
          end
        end
      end
    end

    describe 'touches parent order on update' do
      let!(:parent_order) { create(:splitted_order) }
      let!(:order) { create(:vendor_order_ready_to_ship, parent: parent_order) }

      it 'touches parent order' do
        expect { order.touch }.to change { parent_order.reload.updated_at }
      end
    end
  end

  describe '#cancel' do
    # this test should be improved with real data and VCRs
    context 'when splitted' do
      let(:payment_method) { create(:credit_card_payment_method, stores: [store]) }

      let!(:parent_order) { create(:splitted_order, shipment_cost: 5) }
      # setting shipment_cost to 0 to avoid shipment cost calculation and for easier checking if refunds amounts are correct as we do
      # not refund shipment cost
      let!(:order) { create(:vendor_order_ready_to_ship, with_payment: false, store: store, parent: parent_order, shipment_cost: 0, total: 100, payment_total: 0) }

      let(:payment) do
        create(
          :payment,
          order: order,
          amount: 100,
          state: 'completed',
          payment_method: payment_method
        )
      end

      before do
        # Just to speed up the test, we don't care about the email anyway
        allow(Spree::OrderMailer).to receive(:cancel_email).and_return(double(deliver_later: true))
        order.update_column(:total, 110)
        payment
      end

      context 'single sub-order without 1st party products' do
        before do
          parent_order.line_items.destroy_all

          order.cancel
          parent_order.reload
          order.reload
        end

        it 'marks the splitted payments as void' do
          expect(order.payments.first).to be_void
        end

        it 'marks the parent order and sub-order both as canceled' do
          expect(parent_order.reload).to be_canceled
          expect(parent_order.payment_state).to eq 'void'
          expect(parent_order.shipment_state).to eq 'canceled'
          expect(order).to be_canceled
        end

        it 'marks the splitted order payment status as failed' do
          expect(order.payment_state).to eq 'failed'
        end
      end

      context 'refunds' do
        it 'creates a refund for the sub-order' do
          expect { order.cancel }.to change { Spree::Refund.count }.by(2)

          expect(order.reload.refunds.count).to eq 1
          expect(order.refunds.first.amount).to eq 100
          expect(order.refunds.first.payment).to eq order.payments.first

          expect(parent_order.reload.refunds.count).to eq 1
          expect(parent_order.refunds.first.amount).to eq(order.total + order.platform_fee_total.abs)
        end

        it 'creates a refund for the parent order' do
          order.cancel!

          expect(parent_order.reload.refunds.count).to eq(1)
          expect(parent_order.refunds.last.amount).to eq(order.total + order.platform_fee_total.abs)
        end
      end

      context 'multiple sub-orders' do
        let!(:order_2) { create(:vendor_order_ready_to_ship, store: store, parent: parent_order) }

        context 'only 1 sub-order is canceled' do
          it 'marks the parent order as partially canceled' do
            order.cancel
            parent_order.reload
            expect(parent_order.reload.state).to eq('partially_canceled')
          end
        end

        context 'all sub-orders are canceled' do
          before do
            parent_order.line_items.destroy_all

            parent_order.payments.update_all(state: 'completed', amount: 200)
            parent_order.update_columns(shipment_total: 20)
          end

          it 'marks the parent order as canceled' do
            order.cancel
            expect(parent_order.reload.state).to eq('partially_canceled')
            order_2.cancel
            parent_order.reload
            expect(parent_order.reload).to be_canceled
            expect(parent_order.payment_state).to eq 'void'
            expect(parent_order.shipment_state).to eq 'canceled'
          end

          it 'refunds shipment cost' do
            order.cancel
            order_2.cancel

            expect(parent_order.refunds.count).to eq(2)
            expect(parent_order.refunds.map(&:amount).uniq).to contain_exactly(order.total + order.platform_fee_total.abs)
            expect(parent_order.refunds.map(&:amount).uniq).to contain_exactly(order_2.total + order_2.platform_fee_total.abs)
          end
        end
      end
    end
  end

  describe '#persist_totals' do
    let(:order) { create(:order_with_line_items) }

    it 'updates the platform fee total' do
      expect(order).to receive(:update_column).with(:platform_fee_total, order.platform_fee_total)
      order.persist_totals
    end
  end

  describe '#can_vendor_cancel?' do
    context 'when order is not completed' do
      let(:order) { create(:order, state: 'splitted') }

      it 'returns false' do
        expect(order.can_vendor_cancel?).to be false
      end
    end

    context 'when order is canceled' do
      let(:order) { create(:order, state: 'canceled') }

      it 'returns false' do
        expect(order.can_vendor_cancel?).to be false
      end
    end

    context 'when vendor is not present' do
      let!(:order) { create(:vendor_order, vendor: nil) }

      it 'returns false' do
        expect(order.can_vendor_cancel?).to be false
      end
    end

    context 'when order wasn\'t created in external store' do
      let(:order) { create(:vendor_completed_order_with_totals, vendor: create(:approved_vendor)) }

      it 'returns true' do
        expect(order.can_cancel_in_admin?).to be true
      end
    end
  end

  describe '#can_cancel_in_admin?' do
    context 'when order is not completed' do
      let(:order) { create(:order, state: 'splitted') }

      it 'returns false' do
        expect(order.can_cancel_in_admin?).to be false
      end
    end

    context 'when order is canceled' do
      let(:order) { create(:order, state: 'canceled') }

      it 'returns false' do
        expect(order.can_cancel_in_admin?).to be false
      end
    end

    context 'when order is parent order' do
      let!(:order) { create(:vendor_completed_order_with_totals, vendor: create(:approved_vendor)) }

      it 'returns false' do
        expect(order.parent.can_cancel_in_admin?).to be false
      end
    end

    context 'when order wasn\'t created in external store' do
      let(:order) { create(:vendor_completed_order_with_totals, vendor: create(:approved_vendor)) }

      it 'returns true' do
        expect(order.can_cancel_in_admin?).to be true
      end
    end

    context 'when order is already shipped' do
      let(:order) do
        create(:vendor_order_ready_to_ship, vendor: create(:approved_vendor))
      end

      before do
        order.shipments.find_each(&:ship!)
      end

      it 'returns false' do
        expect(order.can_cancel_in_admin?).to be false
      end
    end
  end

  context 'multi vendor order' do
    let(:parent_order) { create(:completed_order_with_totals) }

    let(:vendor) { create(:approved_vendor) }
    let(:vendor_2) { create(:approved_vendor) }

    let(:product) { create(:product_in_stock, vendor: vendor, price: 90.0) }
    let(:product_2) { create(:product_in_stock, vendor: vendor, price: 49.0) }
    let(:product_3) { create(:product_in_stock, vendor: vendor_2, price: 100.0) }

    let!(:line_item) { create(:line_item, order: parent_order, product: product, price: product.price) }
    let!(:line_item_2) { create(:line_item, order: parent_order, product: product_2, price: product_2.price) }
    let!(:line_item_3) { create(:line_item, order: parent_order, product: product_3, price: product_3.price) }

    let!(:payment) { create(:payment, order: parent_order) }

    describe '#split!' do
      it { expect { parent_order.split! }.to change { parent_order.state }.from('complete').to('splitted') }
    end

    it 'does not send regular confirmation email' do
      expect(Spree::OrderMailer).not_to receive(:confirm_email)
      parent_order.send(:deliver_order_confirmation_email)
    end
  end

  describe '#deliver_splitted_order_confirmation_email' do
    let(:parent_order) { create(:completed_order_with_totals) }

    context 'when send_consumer_transactional_emails store setting is set to true' do
      it 'sends splitted order confirmation email after reaching splitted state' do
        expect(Spree::OrderMailer).to receive_message_chain(:splitted_order_confirm_email, :deliver_later).and_return true
        parent_order.deliver_splitted_order_confirmation_email
      end

      it 'updates confirmation_delivered to true' do
        parent_order.deliver_splitted_order_confirmation_email
        expect(parent_order.reload.confirmation_delivered).to be true
      end
    end

    context 'when send_consumer_transactional_emails store setting is set to false' do
      before do
        parent_order.store.preferred_send_consumer_transactional_emails = false
        parent_order.store.save!
      end

      it 'does not send splitted order confirmation email after reaching splitted state' do
        expect(Spree::OrderMailer).not_to receive(:splitted_order_confirm_email)
        parent_order.deliver_splitted_order_confirmation_email
      end

      it 'does not update confirmation_delivered to true' do
        parent_order.deliver_splitted_order_confirmation_email
        expect(parent_order.reload.confirmation_delivered).to be false
      end
    end
  end

  describe '#deliver_vendor_order_notification_email' do
    let(:vendor) { create(:vendor) }
    let!(:vendor_user) { create(:vendor_user, vendor: vendor) }
    let(:vendor_order) { create(:vendor_completed_order_with_totals, vendor: vendor, store: store) }

    context 'when deliver_vendor_order_notification_email? returns true' do
      before do
        allow(vendor_order).to receive(:deliver_vendor_order_notification_email?).and_return(true)
        clear_enqueued_jobs
      end

      it 'sends splitted order confirmation email after reaching splitted state' do
        expect do
          vendor_order.deliver_vendor_order_notification_email && perform_enqueued_jobs(except: Spree::Addresses::GeocodeAddressJob)
        end.to change { Spree::OrderMailer.deliveries.count }.by 1
      end

      it 'updates confirmation_delivered to true' do
        vendor_order.deliver_vendor_order_notification_email
        expect(vendor_order.reload.confirmation_delivered).to be true
      end
    end

    context 'when deliver_vendor_order_notification_email? returns false' do
      before { allow(vendor_order).to receive(:deliver_vendor_order_notification_email?).and_return(false) }

      it 'does not send splitted order confirmation email after reaching splitted state' do
        perform_enqueued_jobs(except: Spree::Addresses::GeocodeAddressJob)
        expect(Spree::OrderMailer).not_to receive(:vendor_order_confirm_email)
        vendor_order.deliver_vendor_order_notification_email
      end

      it 'does not update confirmation_delivered to true' do
        vendor_order.deliver_vendor_order_notification_email
        expect(vendor_order.reload.confirmation_delivered).to be false
      end
    end

    context 'when in test mode' do
      before do
        allow(store).to receive(:preferred_test_mode).and_return(true)
      end

      it 'does not send vendor order notification email' do
        expect(Spree::OrderMailer).not_to receive(:vendor_order_confirm_email)
        vendor_order.deliver_vendor_order_notification_email
      end

      it 'does not update confirmation_delivered to true' do
        perform_enqueued_jobs
        vendor_order.deliver_vendor_order_notification_email
        expect(vendor_order.reload.confirmation_delivered).to be false
      end
    end
  end

  describe '#deliver_vendor_order_notification_email?' do
    context 'when order is not splitted' do
      let(:order) { create(:order, parent: nil) }

      it 'returns false' do
        expect(order.deliver_vendor_order_notification_email?).to be_falsey
      end
    end

    context 'when confirmation was delivered' do
      let(:order) { create(:order, parent: create(:order), vendor: create(:vendor), confirmation_delivered: true) }

      it 'returns false' do
        expect(order.deliver_vendor_order_notification_email?).to be_falsey
      end
    end

    context 'when order is splitted and confirmation has not been delivered' do
      let(:order) { create(:order, parent: create(:order), vendor: create(:vendor)) }

      it 'returns true' do
        expect(order.deliver_vendor_order_notification_email?).to be_truthy
      end
    end
  end

  describe '#after_cancel' do
    context 'with the gift card covering the whole payment' do
      let(:order) { create(:vendor_completed_order_with_totals, parent: parent_order) }
      let(:parent_order) { create(:splitted_order) }

      let(:gift_card) { create(:gift_card, amount: 50) }

      let!(:store_credit_payment_1) { create(:store_credit_payment, order: order, state: 'completed', amount: 40) }
      let!(:store_credit_payment_2) { create(:store_credit_payment, order: order, state: 'invalid', amount: 40) }

      before do
        parent_order.update_column(:total, 50)
        parent_order.apply_gift_card(gift_card)

        order.update_column(:total, 40)
      end

      it 'voids the completed store credit payments' do
        order.after_cancel

        expect(store_credit_payment_1.reload.state).to eq('void')
        expect(store_credit_payment_2.reload.state).to eq('invalid')
      end
    end
  end

  describe 'shipment state' do
    let(:order) { create(:order_ready_to_ship) }

    context 'when there are multiple shipment states' do
      before do
        create_list(:shipment, 2, order: order, state: 'ready')
      end

      context 'when one of the shipments is shipped' do
        before do
          order.shipments.reload.second.update(state: 'shipped')
        end

        it do
          order.update_with_updater!
          expect(order.reload.shipment_state).to eq('partial')
        end
      end

      context 'when of the shipments is pending' do
        before do
          order.shipments.reload.second.update(state: 'pending')
        end

        it do
          order.update_with_updater!
          expect(order.reload.shipment_state).to eq('pending')
        end
      end
    end

    context 'when all shipments have the same state' do
      before do
        create_list(:shipment, 2, order: order, state: 'shipped')
        order.shipments.update_all(state: 'shipped')
      end

      it do
        order.update_with_updater!
        expect(order.reload.shipment_state).to eq('shipped')
      end
    end
  end

  describe '#total_after_fees' do
    subject(:total_after_fees) { order.total_after_fees }

    context 'for a parent order' do
      let(:order) { create(:order, total: 100, platform_fee_total: 0) }

      it 'returns the order total' do
        expect(total_after_fees).to eq(100)
      end
    end

    context 'for a suborder' do
      let(:order) { create(:vendor_order, total: 100, platform_fee_total: -10) }

      it 'returns the order total excluding platform fee total' do
        expect(total_after_fees).to eq(90)
      end
    end
  end
end
