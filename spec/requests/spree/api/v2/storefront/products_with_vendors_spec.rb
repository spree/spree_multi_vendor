require 'spec_helper'

describe 'API V2 Storefront Products Spec', type: :request do
  let!(:store)                     { Spree::Store.default }
  let!(:products)                  { create_list(:product, 5, stores: [store]) }
  let(:taxonomy)                   { create(:taxonomy, store: store) }
  let!(:taxon)                     { taxonomy.root }
  let(:product_with_taxon)         { create(:product, taxons: [taxon], stores: [store]) }
  let(:product_with_name)          { create(:product, name: 'Test Product', stores: [store]) }
  let(:product_with_price)         { create(:product, price: 13.44, stores: [store]) }
  let!(:option_type)               { create(:option_type) }
  let!(:option_value)              { create(:option_value, option_type: option_type) }
  let(:product_with_option)        { create(:product, option_types: [option_type], stores: [store]) }
  let!(:variant)                   { create(:variant, product: product_with_option, option_values: [option_value]) }
  let(:product)                    { create(:product, stores: [store]) }
  let!(:deleted_product)           { create(:product, deleted_at: Time.current - 1.day, stores: [store]) }
  let!(:discontinued_product)      { create(:product, discontinue_on: Time.current - 1.day, stores: [store]) }
  let!(:not_available_product)     { create(:product, available_on: nil, stores: [store]) }
  let!(:in_stock_product)          { create(:product_in_stock, stores: [store]) }
  let!(:not_backorderable_product) { create(:product_in_stock, :without_backorder, stores: [store]) }
  let!(:property)                  { create(:property) }
  let!(:new_property)              { create(:property) }
  let!(:product_with_property)     { create(:product, stores: [store]) }
  let!(:product_property)          { create(:product_property, property: new_property, product: product_with_property, value: 'Some Value') }
  let!(:product_property2)         { create(:product_property, property: property, product: product_with_property, value: 'Some Value 2') }
  let(:product_with_vendor_a)      { create(:product, vendor: create(:approved_vendor), stores: [store]) }
  let(:product_with_vendor_b)      { create(:product, vendor: create(:approved_vendor), stores: [store]) }

  before { Spree::Api::Config[:api_v2_per_page_limit] = 4 }

  describe 'products#index' do
    context 'include vendors' do
      before { product_with_vendor_a }

      it 'returns products with vendors' do
        get '/api/v2/storefront/products?include=vendor'

        expect(response).to be_successful
        expect(json_response['included'].count).to eq(1)
        expect(json_response['included'].first['type']).to eq('vendor')
        expect(json_response['included'].first['id']).to eq(product_with_vendor_a.vendor.id.to_s)
      end
    end

    context 'with specified vendor_ids' do
      before { get "/api/v2/storefront/products?filter[vendor_ids]=#{product_with_vendor_a.vendor_id},#{product_with_vendor_b.vendor_id}" }

      it_behaves_like 'returns 200 HTTP status'

      it 'returns products with specified vendor_ids' do
        expect(json_response['data']).not_to be_nil
        expect(json_response['data'].count).to eq(2)
        expect(json_response['data'].map(&:first).map(&:last)).to contain_exactly(product_with_vendor_a.id.to_s, product_with_vendor_b.id.to_s)
      end
    end

    context 'with multiple specified options' do
      let!(:color) { Spree::OptionType.find_by(name: 'color') || create(:option_type, :color) }
      let!(:green_color) { color.option_values.find_by(name: 'green') || create(:option_value, option_type: color, name: 'green') }
      let!(:white_color) { color.option_values.find_by(name: 'white') || create(:option_value, option_type: color, name: 'white') }

      let!(:size) { Spree::OptionType.find_by(name: 'size') || create(:option_type, :size) }
      let!(:s_size) { size.option_values.find_by(name: 's') || create(:option_value, option_type: size, name: 's') }
      let!(:m_size) { size.option_values.find_by(name: 'm') || create(:option_value, option_type: size, name: 'm') }

      let(:product_1) { create(:product, option_types: [color, size], stores: [store]) }
      let!(:variant_1) { create(:variant, product: product_1, option_values: [white_color, m_size]) }

      let(:product_2) { create(:product, option_types: [color, size], stores: [store]) }
      let!(:variant_2_1) { create(:variant, product: product_2, option_values: [green_color, s_size]) }
      let!(:variant_2_2) { create(:variant, product: product_2, option_values: [white_color, s_size]) }

      context 'for filters with products' do
        let(:options_filter) do
          [
            "filter[options][#{color.name}]=#{white_color.name}",
            "filter[options][#{size.name}]=#{m_size.name}"
          ].join('&')
        end

        before { get "/api/v2/storefront/products?#{options_filter}&include=option_types,variants.option_values" }

        it_behaves_like 'returns 200 HTTP status'

        it 'returns products with specified options' do
          expect(json_response['data']).to include(have_id(product_1.id.to_s))
          expect(json_response['data']).not_to include(have_id(product_2.id.to_s))

          expect(json_response['included']).to include(have_type('option_type').and(have_attribute(:name).with_value(color.name)))
          expect(json_response['included']).to include(have_type('option_value').and(have_attribute(:name).with_value(white_color.name)))

          expect(json_response['included']).to include(have_type('option_type').and(have_attribute(:name).with_value(size.name)))
          expect(json_response['included']).to include(have_type('option_value').and(have_attribute(:name).with_value(m_size.name)))
        end
      end
    end

    context 'with specified multiple filters' do
      before { get "/api/v2/storefront/products?filter[name]=#{product_with_name.name}&filter[price]=#{product_with_name.price.to_f - 0.02},#{product_with_name.price.to_f + 0.02}" }

      it_behaves_like 'returns 200 HTTP status'

      it 'returns products with specified name and price' do
        expect(json_response['data'].count).to eq 1
        expect(json_response['data'].first).to have_id(product_with_name.id.to_s)
      end
    end

    # Regression test for SD-1439 ambiguous column name: count_on_hand
    context 'with multiple params' do
      before do
        get '/api/v2/storefront/products?filter[backorderable]=true'\
          '&filter[ids]=130'\
          '&filter[in_stock]=true'\
          '&filter[name]=rails'\
          '&filter[options][tshirt-color]=Red'\
          '&filter[price]=10,100'\
          '&filter[properties][brand-name]=alpha'\
          '&filter[purchasable]=true'\
          '&filter[show_deleted]=true'\
          '&filter[show_discontinued]=true'\
          '&filter[skus]=SKU-123,SKU-345'\
          "&filter[taxons]=#{SecureRandom.uuid},#{SecureRandom.uuid},#{SecureRandom.uuid},#{SecureRandom.uuid},#{SecureRandom.uuid}"\
          "&filter[vendor_ids]=#{SecureRandom.uuid},#{SecureRandom.uuid},#{SecureRandom.uuid},#{SecureRandom.uuid}"\
          '&include=default_variant,variants,option_types,product_properties,taxons,images,primary_variant,vendor'\
          '&page=1'\
          '&per_page=25'\
          '&sort=-updated_at,price,-name,created_at,-available_on,sku'
      end

      it_behaves_like 'returns 200 HTTP status'
    end
  end
end
