require 'spec_helper'

describe Spree::Admin::VendorsController, type: :controller do
  stub_authorization!
  render_views

  let(:store) { Spree::Store.default }

  describe '#index' do
    let!(:vendor_one) { create(:approved_vendor, products_count: 1, sales_total: 10, commission_total: 100, name: 'Vendor_one') }
    let!(:vendor_two) { create(:approved_vendor, products_count: 2, sales_total: 20, commission_total: 200) }

    let(:format) { 'html' }

    before do
      get :index, format: format
    end

    it 'renders index' do
      expect(response).to have_http_status(:ok)
    end

    it 'return vendors' do
      expect(assigns(:collection)).to include(vendor_one)
      expect(assigns(:collection)).to include(vendor_two)
    end

    it 'orders by products_count ascending' do
      get :index, params: { q: { s: 'products_count asc' } }
      expect(assigns(:collection).to_a).to eq([vendor_one, vendor_two])
    end

    it 'orders by products_count descending' do
      get :index, params: { q: { s: 'products_count desc' } }
      expect(assigns(:collection).to_a).to eq([vendor_two, vendor_one])
    end

    it 'orders by sales_total ascending' do
      get :index, params: { q: { s: 'sales_total asc' } }
      expect(assigns(:collection).to_a).to eq([vendor_one, vendor_two])
    end

    it 'orders by sales_total descending' do
      get :index, params: { q: { s: 'sales_total desc' } }
      expect(assigns(:collection).to_a).to eq([vendor_two, vendor_one])
    end

    it 'orders by commission_total ascending' do
      get :index, params: { q: { s: 'commission_total asc' } }
      expect(assigns(:collection).to_a).to eq([vendor_one, vendor_two])
    end

    it 'orders by commission_total descending' do
      get :index, params: { q: { s: 'commission_total desc' } }
      expect(assigns(:collection).to_a).to eq([vendor_two, vendor_one])
    end

    it 'orders by join date ascending' do
      get :index, params: { q: { s: 'created_at asc' } }
      expect(assigns(:collection).to_a).to eq([vendor_one, vendor_two])
    end

    it 'orders by join date descending' do
      get :index, params: { q: { s: 'created_at desc' } }
      expect(assigns(:collection).to_a).to eq([vendor_two, vendor_one])
    end

    it 'should only give distinct vendor when searched with vendor name' do
      get :index, params: { q: { name_eq: 'Vendor_one' } }
      expect(assigns(:collection).to_a).to contain_exactly(vendor_one)
      expect(assigns(:collection).to_a.count).to eq(1)
    end

    it 'should only give vendors with integration as shopify' do
      get :index, params: { q: { integration_eq: 'shopify' } }
      expect(assigns(:collection).to_a).to contain_exactly(vendor_one, vendor_two)
      expect(assigns(:collection).to_a.count).to eq(2)
    end

    context 'CSV format' do
      let(:format) { 'csv' }

      before do
        get :index, format: format
      end

      it 'renders CSV' do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe '#update' do
    subject(:update_vendor) do
      post :update, params: { id: vendor.id, vendor: vendor_update_params }
    end

    let!(:vendor) { create(:vendor) }

    context 'adds a returns address' do
      let(:country) { Spree::Country.find_by(iso: 'US') }
      let(:state) { create(:state, country: country, abbr: 'NY') }

      let(:vendor_update_params) do
        {
          returns_address_attributes: {
            city: 'New York',
            country_id: country.id,
            state_id: state.id,
            zipcode: '10036',
            address1: '123 Main St'
          }
        }
      end

      it 'creates a new returns address' do
        expect { update_vendor }.to change { Spree::ReturnsAddress.count }.by(1)
        vendor.reload
        expect(vendor.returns_address.city).to eq('New York')
        expect(vendor.returns_address.country_id).to eq(country.id)
        expect(vendor.returns_address.state_id).to eq(state.id)
        expect(vendor.returns_address.zipcode).to eq('10036')
        expect(vendor.returns_address.address1).to eq('123 Main St')
      end

      context 'update existing address' do
        let(:returns_address) { create(:returns_address, city: 'New York', country: country, state: state) }

        before do
          vendor.returns_address = returns_address
          vendor.save!
        end

        let(:vendor_update_params) do
          { returns_address_attributes: { id: vendor.returns_address.id, city: 'New Jersey' } }
        end

        it 'updates address' do
          expect { update_vendor }.to change { vendor.returns_address.reload.city }.from('New York').to('New Jersey')
        end
      end
    end
  end

  describe '#show' do
    let(:vendor) { create(:approved_vendor) }
    let(:vendor_user) { create(:vendor_user, vendor: vendor) }
    let(:store_role) { create(:role_user, resource: store, user: vendor_user) }

    before do
      store_role
    end

    it 'renders show' do
      get :show, params: { id: vendor.id }
      expect(response).to have_http_status(:ok)
    end

    it 'assigns @vendor_users with roles for proper resource' do
      get :show, params: { id: vendor.id }
      expect(assigns(:vendor_users).first.role_users.size).to eq(1)
      expect(assigns(:vendor_users).first.role_users.first).not_to eq(store_role)
    end
  end
end
