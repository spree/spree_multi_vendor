require 'spec_helper'

describe Spree::Admin::ProductsController, type: :controller do
  stub_authorization!
  render_views

  let(:admin_user) { create(:admin_user) }

  before do
    allow(controller).to receive(:current_ability).and_call_original
  end

  let(:store) { Spree::Store.default }

  describe 'GET #index' do
    let(:vendor) { create(:vendor, name: 'Test Vendor') }
    let!(:non_vendor_product) { create(:product) }
    let!(:vendor_product) { create(:product, vendor: vendor) }

    context 'when vendor is present' do
      it 'filters products by vendor ID' do
        get :index, params: { vendor_id: vendor.id }

        expect(assigns(:collection)).to contain_exactly(vendor_product)
      end

      it 'filters products by vendor slug' do
        get :index, params: { vendor_id: vendor.slug }

        expect(assigns(:collection)).to contain_exactly(vendor_product)
      end
    end

    context 'when vendor is not present' do
      it 'does not filter products by vendor' do
        get :index, params: { vendor_id: nil }

        expect(assigns(:collection)).to contain_exactly(vendor_product, non_vendor_product)
      end
    end

    context 'when vendor is not found' do
      it 'redirects to the index page' do
        get :index, params: { vendor_id: 'invalid-slug' }

        expect(response).to redirect_to(spree.admin_products_path)
      end
    end
  end

  describe 'PUT #update' do
    let!(:product) { create(:product, stores: [store], status: 'active') }
    let(:product_params) { { status: 'draft', make_active_at: Time.current.beginning_of_day } }
    let(:send_request) do
      put :update, params: {
        id: product.to_param,
        product: product_params
      }
    end

    context 'updating existing variants' do
      let(:color_option_type) { Spree::OptionType.find_by(name: 'color') || create(:option_type, name: 'color', presentation: 'Color') }
      let(:size_option_type) { Spree::OptionType.find_by(name: 'size') || create(:option_type, name: 'size', presentation: 'Size') }
      let(:red_option_value) { color_option_type.option_values.find_by(name: 'red') || create(:option_value, name: 'red', option_type: color_option_type) }
      let(:blue_option_value) { color_option_type.option_values.find_by(name: 'blue') || create(:option_value, name: 'blue', option_type: color_option_type) }
      let(:small_option_value) { size_option_type.option_values.find_by(name: 'small') || create(:option_value, name: 'small', option_type: size_option_type) }
      let(:large_option_value) { size_option_type.option_values.find_by(name: 'large') || create(:option_value, name: 'large', option_type: size_option_type) }

      let(:variant1) { create(:variant, product: product, option_values: [red_option_value, small_option_value], price: 100) }
      let(:variant2) { create(:variant, product: product, option_values: [blue_option_value, large_option_value], price: 100) }

      let(:variant1_stock_item) { variant1.stock_items.first }
      let(:variant2_stock_item) { variant2.stock_items.first }

      let(:product_params) do
        {
          name: 'Product',
          variants_attributes: {
            '0' => {
              prices_attributes: {
                '0': { currency: 'PLN', amount: 10, id: variant1.price_in('PLN')&.id },
                '1': { currency: 'USD', amount: 20, id: variant1.price_in('USD')&.id }
              },
              id: variant1.id,
              stock_items_attributes: {
                '0' => {
                  id: variant1_stock_item.id,
                  count_on_hand: 10,
                  stock_location_id: variant1_stock_item.stock_location_id,
                }
              },
              options: [
                {
                  id: red_option_value.id,
                  name: 'Color',
                  position: 1,
                  option_value_presentation: red_option_value.presentation,
                  option_value_name: red_option_value.name
                },
                {
                  id: small_option_value.id,
                  name: 'Size',
                  position: 2,
                  option_value_presentation: small_option_value.presentation,
                  option_value_name: small_option_value.name
                }
              ]
            },
            '1' => {
              prices_attributes: {
                '0': { currency: 'PLN', amount: 30, id: variant2.price_in('PLN')&.id },
                '1': { currency: 'USD', amount: 40, id: variant2.price_in('USD')&.id }
              },
              id: variant2.id,
              stock_items_attributes: {
                '0' => {
                  id: variant2_stock_item.id,
                  count_on_hand: 20,
                  stock_location_id: variant2_stock_item.stock_location_id,
                }
              },
              options: [
                {
                  id: blue_option_value.id,
                  name: 'Color',
                  position: 1,
                  option_value_presentation: blue_option_value.presentation,
                  option_value_name: blue_option_value.name
                },
                {
                  id: large_option_value.id,
                  name: 'Size',
                  position: 2,
                  option_value_presentation: large_option_value.presentation,
                  option_value_name: large_option_value.name
                }
              ]
            }
          }
        }
      end
    end

    context 'with platform_fee param' do
      let(:product_params) do
        {
          platform_fee: '22.4'
        }
      end

      it 'updates spree_products.platform_fee attribute' do
        expect { send_request }.to change { product.reload.platform_fee }.from(nil).to(22.4)
      end
    end
  end

  describe 'GET #bulk_modal' do
    context 'as a vendor user' do
      let(:vendor) { create(:approved_vendor) }
      let(:admin_user) { create(:vendor_user, vendor: vendor) }

      it 'renders modal' do
        get :bulk_modal

        expect(response).to render_template('bulk_modal')
      end
    end
  end
end
