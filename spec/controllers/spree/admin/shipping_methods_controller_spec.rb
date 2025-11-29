require 'spec_helper'

RSpec.describe Spree::Admin::ShippingMethodsController, type: :controller do
  stub_authorization!
  render_views

  let!(:vendor) { create(:vendor) }
  let(:admin_user) { create(:vendor_user, vendor: vendor) }

  describe 'GET #index' do
    let!(:vendor_shipping_methods) { create_list(:shipping_method, 2, vendor: vendor) }
    let!(:other_shipping_method) { create(:shipping_method) }

    it 'renders vendor shipping methods' do
      get :index
      expect(response).to render_template(:index)
      expect(assigns(:collection)).to contain_exactly(*vendor_shipping_methods)
    end
  end

  describe 'POST #create' do
    let(:shipping_method_attributes) do
      attributes_for(
        :shipping_method,
        zone_ids: [zone.id],
        shipping_category_ids: [shipping_category.id],
        calculator_type: 'Spree::Calculator::Shipping::FlatRate'
      )
    end

    let(:zone) { create(:zone) }
    let(:shipping_category) { create(:shipping_category) }

    it 'creates a new vendor shipping method' do
      expect { post :create, params: { shipping_method: shipping_method_attributes } }.to change(Spree::ShippingMethod, :count).by(1)

      expect(Spree::ShippingMethod.last.vendor).to eq(vendor)
    end
  end
end
