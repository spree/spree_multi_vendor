require 'spec_helper'

describe Spree::Admin::RefundsController, type: :controller do
  stub_authorization!
  render_views

  let(:admin_user) { create(:admin_user) }

  before do
    allow(controller).to receive(:current_ability).and_return(Spree::Dependencies.ability_class.constantize.new(admin_user))
  end

  describe '#new' do
    let(:payment) { create(:payment, state: 'completed', order: order) }
    subject { get :new, params: { payment_id: payment.number, order_id: order.number } }

    before do
      subject
    end

    context 'when payment order is parent order' do
      let(:order) { create(:completed_order_with_totals, state: 'splitted') }

      it 'should return error' do
        expect(flash['error']).to eq('Authorization Failure')
        expect(response).to be_redirect
      end
    end

    context 'when payment order is vendor order' do
      let(:order) { create(:vendor_completed_order_with_totals) }

      it 'should not return error' do
        expect(flash['error']).to be nil
        expect(response).to be_successful
      end
    end
  end
end
