require 'spec_helper'

RSpec.describe 'Storefront API v2 Orders spec', type: :request do
  let(:store) { Spree::Store.default }
  let!(:user) { create(:user_with_addresses) }
  let!(:order) { create(:order, state: 'complete', user: user, completed_at: Time.current, store: store) }

  before do
    allow(Spree::Api::Config).to receive(:[]).and_call_original
    allow(Spree::Api::Config).to receive(:[]).with(:api_v2_per_page_limit).and_return(2)
  end

  include_context 'API v2 tokens'

  def expect_order_json(json)
    expect(json).to be_present
    expect(json).to have_id(order.id.to_s)
    expect(json).to have_type('order')
    expect(json).to have_attribute(:number).with_value(order.number)
    expect(json).to have_attribute(:state).with_value(order.state)
    expect(json).to have_attribute(:token).with_value(order.token)
    expect(json).to have_attribute(:total).with_value(order.total.to_s)
    expect(json).to have_attribute(:item_total).with_value(order.item_total.to_s)
    expect(json).to have_attribute(:ship_total).with_value(order.ship_total.to_s)
    expect(json).to have_attribute(:adjustment_total).with_value(order.adjustment_total.to_s)
    expect(json).to have_attribute(:included_tax_total).with_value(order.included_tax_total.to_s)
    expect(json).to have_attribute(:additional_tax_total).with_value(order.additional_tax_total.to_s)
    expect(json).to have_attribute(:display_additional_tax_total).with_value(order.display_additional_tax_total.to_s)
    expect(json).to have_attribute(:display_included_tax_total).with_value(order.display_included_tax_total.to_s)
    expect(json).to have_attribute(:tax_total).with_value(order.tax_total.to_s)
    expect(json).to have_attribute(:currency).with_value(order.currency.to_s)
    expect(json).to have_attribute(:email).with_value(order.email)
    expect(json).to have_attribute(:display_item_total).with_value(order.display_item_total.to_s)
    expect(json).to have_attribute(:display_ship_total).with_value(order.display_ship_total.to_s)
    expect(json).to have_attribute(:display_adjustment_total).with_value(order.display_adjustment_total.to_s)
    expect(json).to have_attribute(:display_tax_total).with_value(order.display_tax_total.to_s)
    expect(json).to have_attribute(:item_count).with_value(order.item_count)
    expect(json).to have_attribute(:special_instructions).with_value(order.special_instructions)
    expect(json).to have_attribute(:promo_total).with_value(order.promo_total.to_s)
    expect(json).to have_attribute(:display_promo_total).with_value(order.display_promo_total.to_s)
    expect(json).to have_attribute(:display_total).with_value(order.display_total.to_s)
    expect(json).to have_attribute(:public_metadata).with_value(order.public_metadata)
    expect(json).to have_relationships(:user, :line_items, :variants, :billing_address, :shipping_address, :payments, :shipments, :promotions)
  end

  shared_examples 'returns included resource' do |resource|
    it 'returns included resource' do
      expect(json_response['included'].size).to eq 1
      expect(json_response['included'][0]).to have_type(resource)
    end
  end

  describe 'orders#index' do
    context 'with option: include' do
      let!(:vendor_order) { create(:vendor_order_with_line_items, user: user, store: store, parent: order) }

      shared_examples 'returns orders' do
        it 'returns orders' do
          expect(json_response['data'].size).to eq 1
          expect(json_response['data']).to be_kind_of(Array)

          expect_order_json(json_response['data'].first)
        end
      end

      before { get "/api/v2/storefront/account/orders?include=#{include}", headers: headers_bearer }

      context 'including vendors' do
        let(:include) { 'vendors' }

        it_behaves_like 'returns orders'

        it_behaves_like 'returns included resource', 'vendor'
      end
    end

    context 'with splitted orders' do
      let!(:order_2) { create(:order, state: 'splitted', user: user, completed_at: Time.current) }

      before { get '/api/v2/storefront/account/orders', headers: headers_bearer }

      it 'returns splitted orders' do
        expect(json_response['data'].count).to eq 2
        expect(json_response['data'].pluck(:id)).to include(order_2.id.to_s)
      end
    end

    context 'with vendor orders' do
      let(:order_2) { create(:vendor_order, state: 'complete', user: user, completed_at: Time.current) }

      before { get '/api/v2/storefront/account/orders', headers: headers_bearer }

      it 'does not return vendor orders' do
        expect(json_response['data'].count).to eq 1
        expect(json_response['data'].pluck(:id)).not_to include(order_2.id.to_s)
      end
    end
  end

  describe 'orders#show' do
    let(:user) { create(:user_with_addresses) }
    let(:order) { create(:order, state: 'complete', user: user, completed_at: Time.current, store: store) }

    shared_examples 'returns valid order JSON' do
      it 'returns valid order JSON' do
        expect_order_json(json_response['data'])
      end
    end

    context 'with option: include' do
      let!(:vendor_order) { create(:vendor_order_with_line_items, user: user, store: store, parent: order) }

      before { get "/api/v2/storefront/account/orders/#{order.number}?include=#{include}", headers: headers_bearer }

      context 'including vendors' do
        let(:include) { 'vendors' }

        it_behaves_like 'returns valid order JSON'

        it_behaves_like 'returns included resource', 'vendor'
      end
    end
  end
end
