require 'spec_helper'

describe Spree::Admin::OrdersController, type: :controller do
  stub_authorization!
  render_views

  let(:admin_user) { create(:admin_user) }
  let(:store) { Spree::Store.default }

  before do
    allow(controller).to receive(:current_ability).and_call_original
  end

  describe 'GET #index' do
    let(:vendor) { create(:vendor, name: 'Test Vendor') }

    let!(:main_order) { create(:completed_order_with_totals, store: store, vendor: nil) }

    let!(:parent_order_1) { create(:completed_order_with_totals, store: store, vendor: nil) }
    let!(:vendor_order_1) { create(:vendor_completed_order_with_totals, store: store, vendor: vendor, parent: parent_order_1) }

    let!(:parent_order_2) { create(:completed_order_with_totals, store: store, vendor: nil) }
    let!(:vendor_order_2) { create(:vendor_completed_order_with_totals, store: store, parent: parent_order_2) }

    context 'when vendor is present' do
      it 'filters orders by vendor ID' do
        get :index, params: { vendor_id: vendor.id }

        expect(assigns(:orders)).to contain_exactly(parent_order_1)
      end

      it 'filters orders by vendor slug' do
        get :index, params: { vendor_id: vendor.slug }

        expect(assigns(:orders)).to contain_exactly(parent_order_1)
      end
    end

    context 'when vendor is not present' do
      it 'shows all orders' do
        get :index, params: { vendor_id: nil }

        expect(assigns(:orders)).to contain_exactly(main_order, parent_order_1, parent_order_2)
      end
    end

    context 'when vendor_id is invalid' do
      it 'redirects to the index page' do
        get :index, params: { vendor_id: 'invalid-slug' }

        expect(response).to redirect_to(spree.admin_orders_path)
      end
    end

    context 'when current user is a vendor user' do
      let(:vendor_user) { create(:vendor_user, vendor: vendor) }

      before do
        allow(controller).to receive(:current_spree_user).and_return(vendor_user)
        allow(controller).to receive(:current_vendor).and_return(vendor)
      end

      it 'does not load vendor from params when current_vendor is present' do
        get :index, params: { vendor_id: 'different-vendor-id' }

        expect(assigns(:vendor)).to be_nil
      end
    end
  end
end
