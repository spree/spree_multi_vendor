require 'spec_helper'

RSpec.describe Spree::Account::OrdersController, type: :controller do
  let(:store) { Spree::Store.default }

  let!(:parent_order) { create(:splitted_order, user: user, store: store, payment_gateway: check_payment_method) }
  let!(:order) { create(:vendor_order_ready_to_ship, parent: parent_order, user: user, store: store) }

  let(:check_payment_method) { create(:check_payment_method, stores: [store]) }
  let(:user) { create(:user) }

  render_views

  before do
    allow(controller).to receive(:current_store).and_return(store)
    allow(controller).to receive(:spree_login_path).and_return('/login')
  end

  describe '#show' do
    subject { get :show, params: { id: parent_order.number } }

    context 'when user is logged in' do
      before do
        allow(controller).to receive(:try_spree_current_user).and_return(user)
        allow(controller).to receive(:spree_current_user).and_return(user)
      end

      it 'shows the order details' do
        subject
        expect(response).to have_http_status(:ok)

        expect(assigns(:order)).to eq(parent_order)

        expect(assigns(:shipments).length).to eq(2)
        expect(assigns(:shipments)).to contain_exactly(order.shipments.first, parent_order.shipments.first)
      end

      it 'renders the order details' do
        subject
        expect(response).to render_template(:show)
      end

      context 'when order number does not exist' do
        subject { get :show, params: { id: 'invalid' } }

        it 'raises ActiveRecord::RecordNotFound' do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when user is not logged in' do
      it 'redirects to login page' do
        expect(subject).to have_http_status(302)
      end
    end
  end
end
