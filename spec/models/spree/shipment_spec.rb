require 'spec_helper'

RSpec.describe Spree::Shipment do
  let(:store) { Spree::Store.default }
  let(:shipment) { create(:shipment, state: :ready, order: order, stock_location: stock_location) }
  let(:stock_location) { create(:stock_location, vendor: vendor) }
  let(:vendor) { create(:vendor) }
  let(:order) do
    create(
      :vendor_order_ready_to_ship,
      parent: parent_order,
      store: store,
      vendor: vendor,
      total: payment_amount
    )
  end
  let(:payment) do
    create(
      :payment,
      state: :completed,
      amount: payment_amount,
      order: order,
      payment_method: gateway
    )
  end
  let!(:gateway) { create(:credit_card_payment_method, stores: [store]) }
  let(:payment_amount) { 50.0 }
  let(:parent_order) { create(:order, state: 'splitted', parent: nil, number: 'PARENT', completed_at: Time.current) }

  before do
    order.update(payment_total: 0)
    payment
  end

  describe '#cancel' do
    it 'allows shipped shipment to be canceled' do
      shipment.ship!
      expect(shipment.shipped?).to eq true

      shipment.cancel!
      expect(shipment.canceled?).to eq true
    end
  end

  context 'vendor order shipment' do
    let(:parent_order) { create(:order, shipment_state: 'ready', state: 'splitted', completed_at: Time.current) }
    let!(:vendor_order) { create(:vendor_order, vendor: create(:vendor), parent: parent_order, shipment_state: 'ready') }
    let!(:shipment) do
      create(:shipment, state: 'ready', order: vendor_order, tracking: '123456789')
    end

    before do
      order.shipments.delete_all
      allow(vendor_order).to receive(:can_ship?).and_return(true)
    end

    it 'updates both vendor and parent order state' do
      expect { shipment.ship! }.to change { vendor_order.reload.shipment_state }.from('ready').to('shipped').and change {
        parent_order.reload.shipment_state
      }.from('ready').to('shipped')
    end

    context 'multiple shipments with diferent statuses' do
      let!(:vendor_order_2) { create(:vendor_order, vendor: create(:vendor), parent: parent_order, shipment_state: 'ready') }
      let!(:shipment2) { create(:shipment, state: 'ready', order: vendor_order) }

      it 'updates both vendor and parent order state' do
        expect { shipment.ship! }.to change { parent_order.reload.shipment_state }.from('ready').to('partial')
      end
    end
  end
end
