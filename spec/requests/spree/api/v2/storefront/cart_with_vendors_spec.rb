require 'spec_helper'

describe 'API V2 Storefront Cart Spec', type: :request do
  let!(:store) { Spree::Store.default }
  let(:currency) { store.default_currency }
  let(:user)  { create(:user) }
  let(:order) { create(:order, user: user, store: store, currency: currency) }
  let!(:vendor) { create(:approved_vendor) }
  let(:product) { create(:product_in_stock, stores: [store], vendor: vendor) }
  let(:variant) { product.default_variant }

  include_context 'API v2 tokens'

  describe 'cart#add_item' do
    let(:options) { {} }
    let(:params) { { variant_id: variant.id, quantity: 5, options: options, include: 'variants,line_items.vendor' } }
    let(:execute) { post '/api/v2/storefront/cart/add_item', params: params, headers: headers_order_token }

    before { execute }

    it_behaves_like 'returns 200 HTTP status'
    it_behaves_like 'returns valid cart JSON'

    it 'adds vendor item' do
      order.reload

      expect(order.line_items.count).to eq(1)
      expect(order.line_items.last.variant).to eq(variant)
      expect(order.line_items.last.vendor).to eq(vendor)
      expect(order.line_items.last.quantity).to eq(5)
      expect(json_response['included']).to include(have_type('variant').and(have_id(variant.id.to_s)))
      expect(json_response['included']).to include(have_type('vendor').and(have_id(vendor.id.to_s)))
    end
  end

  describe 'cart#show' do
    let!(:line_item) { create(:line_item, order: order, variant: variant, quantity: 5) }

    let(:params) { { include: 'line_items.vendor' } }

    let(:execute) { get '/api/v2/storefront/cart', headers: headers_order_token, params: params }

    before { execute }

    it_behaves_like 'returns 200 HTTP status'

    it 'returns valid cart JSON' do
      expect(json_response['included']).to include(have_type('vendor').and(have_id(vendor.id.to_s)))
    end

    context 'including vendors directly' do
      let(:params) { { include: 'vendors' } }

      it 'returns valid cart JSON' do
        expect(json_response['included']).to include(have_type('vendor').and(have_id(vendor.id.to_s)))
      end
    end
  end
end
