require 'spec_helper'

describe 'API V2 Storefront Checkout Spec', type: :request do
  let!(:store) { Spree::Store.default }
  let!(:vendor) { create(:approved_vendor) }

  let(:currency) { store.default_currency }
  let(:user)  { create(:user) }
  let(:order) { create(:order, user: user, store: store, currency: currency) }
  let(:payment) { create(:payment, amount: order.total, order: order) }
  let(:shipment) { create(:shipment, order: order) }

  let(:address) do
    {
      firstname: 'John',
      lastname: 'Doe',
      address1: '7735 Old Georgetown Road',
      city: 'Bethesda',
      phone: '3014445002',
      zipcode: '20814',
      state_id: state.id,
      country_iso: country.iso
    }
  end

  let(:payment_source_attributes) do
    {
      gateway_payment_profile_id: 'BGS-123',
      gateway_customer_profile_id: 'BGS-123',
      month: 1.month.from_now.month,
      year: 1.month.from_now.year,
      name: 'Spree Commerce',
      last_digits: '1111'
    }
  end
  let(:payment_params) do
    {
      order: {
        payments_attributes: [
          {
            payment_method_id: payment_method.id
          }
        ]
      },
      payment_source: {
        payment_method.id.to_s => payment_source_attributes
      }
    }
  end

  include_context 'API v2 tokens'

  describe 'checkout#shipping_rates' do
    let(:execute) { get '/api/v2/storefront/checkout/shipping_rates', headers: headers }

    let(:country) { store.default_country }
    let(:zone) { create(:zone) }
    let(:shipping_method) { create(:shipping_method, vendor: vendor) }
    let(:shipping_method_2) { create(:shipping_method, vendor: vendor) }
    let(:address) { create(:address, country: country) }

    let(:shipment) { order.shipments.first }
    let(:shipping_rate) { shipment.selected_shipping_rate }
    let(:shipping_rate_2) { shipment.shipping_rates.where(selected: false).first }

    shared_examples 'returns a list of shipments with shipping rates' do
      before do
        order.shipping_address = address
        order.save!
        zone.countries << country
        shipping_method.zones = [zone]
        shipping_method_2.zones = [zone]
        order.create_proposed_shipments
        execute
        order.reload
      end

      it_behaves_like 'returns 200 HTTP status'

      it 'returns valid shipments JSON' do
        expect(json_response['data']).not_to be_empty
        expect(json_response['data'].size).to eq(order.shipments.count)
        expect(json_response['data'][0]).to have_id(shipment.id.to_s)
        expect(json_response['data'][0]).to have_type('shipment')
        expect(json_response['data'][0]).to have_relationships(:shipping_rates)
        expect(json_response['included']).to be_present
        expect(json_response['included'].size).to eq(shipment.shipping_rates.count + 2)
        [{ shipping_method: shipping_method, shipping_rate: shipping_rate },
         { shipping_method: shipping_method_2, shipping_rate: shipping_rate_2 }].each do |shipping|
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_attribute(:name).with_value(shipping[:shipping_method].name)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_attribute(:shipping_method_id).with_value(shipping[:shipping_method].id.to_s)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_id(shipping[:shipping_rate].id.to_s)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_attribute(:cost).with_value(shipping[:shipping_rate].cost.to_s)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_attribute(:tax_amount).with_value(shipping[:shipping_rate].tax_amount.to_s)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_attribute(:selected).with_value(shipping[:shipping_rate].selected)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_attribute(:final_price).with_value(shipping[:shipping_rate].final_price.to_s)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_attribute(:free).with_value(shipping[:shipping_rate].free?)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_attribute(:display_final_price).with_value(shipping[:shipping_rate].display_final_price.to_s)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_attribute(:display_cost).with_value(shipping[:shipping_rate].display_cost.to_s)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_attribute(:display_tax_amount).with_value(shipping[:shipping_rate].display_tax_amount.to_s)))
          expect(json_response['included']).to include(have_type('shipping_rate').and(have_relationship(:shipping_method).with_data({ 'id' => shipping[:shipping_method].id.to_s, 'type' => 'shipping_method' })))
        end
        expect(json_response['included']).to include(have_type('stock_location').and(have_id(shipment.stock_location_id.to_s)))
        expect(json_response['included']).to include(have_type('stock_location').and(have_attribute(:name).with_value(shipment.stock_location.name)))
      end
    end

    context 'as a guest user' do
      include_context 'creates vendor guest order with guest token'

      it_behaves_like 'returns a list of shipments with shipping rates'
    end

    context 'as a signed in user' do
      include_context 'vendor order with a physical line item'

      it_behaves_like 'returns a list of shipments with shipping rates'
    end
  end

  describe 'checkout#select_shipping_method' do
    let(:headers) { headers_bearer }
    let(:params) do
      {
        shipping_method_id: shipping_method_2.id
      }
    end
    let(:zone) { create(:zone_with_country) }

    let(:country) { create(:country) }
    let(:order) { create(:order, store: store, user: user, ship_address: create(:address, user: user, country: country)) }
    let!(:line_item) { create(:vendor_line_item, order: order, vendor: vendor) }
    let(:shipping_category) { order.products.first.shipping_category }
    let!(:shipping_method) do
      create(:shipping_method, vendor: vendor, zones: [zone], shipping_categories: [shipping_category]) do |shipping_method|
        shipping_method.calculator.preferred_amount = 10
        shipping_method.calculator.save
      end
    end
    let!(:shipping_method_2) do
      create(:shipping_method, vendor: vendor, zones: [zone], shipping_categories: [shipping_category]) do |shipping_method|
        shipping_method.calculator.preferred_amount = 15
        shipping_method.calculator.save
      end
    end
    let!(:shipping_method_3) do
      create(:shipping_method, vendor: vendor, zones: [create(:zone)], shipping_categories: [shipping_category]) do |shipping_method|
        shipping_method.calculator.preferred_amount = 5
        shipping_method.calculator.save
      end
    end
    let(:shipment) { order.shipments.first }
    let(:selected_shipping_rate) { shipment.selected_shipping_rate }
    let(:execute) { patch '/api/v2/storefront/checkout/select_shipping_method?include=shipments.vendor', headers: headers, params: params }

    before do
      zone.countries << country
      # making sure our store is in the geo zone supported by shipping method
      store.update(checkout_zone: zone)
      # generate shipping rates
      get '/api/v2/storefront/checkout/shipping_rates', headers: headers
    end

    context 'one shipment' do
      context 'valid shipping method' do
        before { execute }

        it_behaves_like 'returns 200 HTTP status'

        it 'sets selected shipping method for shipment' do
          expect(json_response['included']).to include(have_type('shipment').and(have_id(shipment.id.to_s)))
          expect(json_response['included']).to include(have_type('vendor').and(have_id(vendor.id.to_s)))
          expect(json_response['included'][1]).to have_relationship(:selected_shipping_rate).with_data({ 'id' => selected_shipping_rate.id.to_s,
                                                                                                         'type' => 'shipping_rate' })
          expect(selected_shipping_rate.shipping_method).to eq(shipping_method_2)
        end
      end

      context 'missing shipping method' do
        let(:params) do
          {
            shipping_method_id: shipping_method_3.id
          }
        end

        before { execute }

        it_behaves_like 'returns 422 HTTP status'
      end
    end
  end

  orders_requiring_delivery = ['vendor order with a physical line item', 'vendor order with a physical and digital line item'].freeze

  orders_requiring_delivery.each do |physical_goods_context|
    describe "full checkout flow (#{physical_goods_context})" do
      let!(:country) { create(:country) }
      let(:state) { create(:state, country: country) }
      let!(:shipping_method) do
        create(:shipping_method, vendor: vendor).tap do |shipping_method|
          shipping_method.zones = [zone]
        end
      end
      let!(:zone) { create(:zone) }
      let!(:zone_member) { create(:zone_member, zone: zone, zoneable: country) }
      let!(:payment_method) { create(:credit_card_payment_method, stores: [store]) }

      let(:customer_params) do
        {
          order: {
            email: 'new@customer.org',
            bill_address_attributes: address,
            ship_address_attributes: address
          }
        }
      end

      let(:shipment_params) do
        {
          order: {
            shipments_attributes: [
              { selected_shipping_rate_id: shipping_rate_id, id: shipment_id }
            ]
          }
        }
      end

      let(:shipping_rate_id) do
        json_response['data'].first['relationships']['shipping_rates']['data'].first['id']
      end
      let(:shipment_id) { json_response['data'].first['id'] }

      shared_examples 'transitions through checkout from start to finish' do
        before do
          zone.countries << country
          shipping_method.zones = [zone]
        end

        it 'completes checkout' do
          # we need to set customer information (email, billing & shipping address)
          patch '/api/v2/storefront/checkout', params: customer_params, headers: headers
          expect(response.status).to eq(200)

          # getting back shipping rates
          get '/api/v2/storefront/checkout/shipping_rates', headers: headers
          expect(response.status).to eq(200)

          # selecting shipping method
          patch '/api/v2/storefront/checkout', params: shipment_params, headers: headers
          expect(response.status).to eq(200)

          # getting back list of available payment methods
          get '/api/v2/storefront/checkout/payment_methods', headers: headers
          expect(response.status).to eq(200)
          expect(json_response['data'].first['id']).to eq(payment_method.id.to_s)

          # creating a CC for selected payment method
          patch '/api/v2/storefront/checkout', params: payment_params, headers: headers
          expect(response.status).to eq(200)

          # complete the checkout
          patch '/api/v2/storefront/checkout/complete', headers: headers
          expect(response.status).to eq(200)
          expect(order.reload.completed_at).not_to be_nil
          expect(order.state).to eq('complete')
          expect(order.payments.valid.first.payment_method).to eq(payment_method)
        end
      end

      context 'as a guest user' do
        include_context 'creates vendor guest order with guest token'

        it_behaves_like 'transitions through checkout from start to finish'
      end

      context 'as a signed in user' do
        include_context physical_goods_context

        it_behaves_like 'transitions through checkout from start to finish'
      end
    end
  end

  describe 'full checkout flow digital' do
    let!(:country) { create(:country) }
    let(:state) { create(:state, country: country) }
    let!(:shipping_method) do
      create(:shipping_method, vendor: vendor).tap do |shipping_method|
        shipping_method.zones = [zone]
      end
    end
    let!(:zone) { create(:zone) }
    let!(:zone_member) { create(:zone_member, zone: zone, zoneable: country) }
    let!(:payment_method) { create(:credit_card_payment_method, stores: [store]) }

    let(:customer_params) do
      {
        order: {
          email: 'new@customer.org',
          bill_address_attributes: address,
          ship_address_attributes: address
        }
      }
    end

    let(:shipment_params) do
      {
        order: {
          shipments_attributes: [
            { selected_shipping_rate_id: shipping_rate_id, id: shipment_id }
          ]
        }
      }
    end

    let(:shipping_rate_id) do
      json_response['data'].first['relationships']['shipping_rates']['data'].first['id']
    end
    let(:shipment_id) { json_response['data'].first['id'] }

    shared_examples 'transitions through checkout from start to finish' do
      before do
        zone.countries << country
        shipping_method.zones = [zone]
      end

      it 'completes checkout skipping delivery stage' do
        # we need to set customer information (email, billing & shipping address)
        patch '/api/v2/storefront/checkout', params: customer_params, headers: headers
        expect(response.status).to eq(200)

        # getting back list of available payment methods
        get '/api/v2/storefront/checkout/payment_methods', headers: headers
        expect(response.status).to eq(200)
        expect(json_response['data'].first['id']).to eq(payment_method.id.to_s)

        # creating a CC for selected payment method
        patch '/api/v2/storefront/checkout', params: payment_params, headers: headers
        expect(response.status).to eq(200)

        # complete the checkout
        patch '/api/v2/storefront/checkout/complete', headers: headers
        expect(response.status).to eq(200)
        expect(order.reload.completed_at).not_to be_nil
        expect(order.state).to eq('complete')
        expect(order.payments.valid.first.payment_method).to eq(payment_method)
      end
    end

    context 'as a guest user' do
      include_context 'creates vendor guest order with guest token'

      it_behaves_like 'transitions through checkout from start to finish'
    end

    context 'as a signed in user' do
      include_context 'vendor order with a digital line item'

      it_behaves_like 'transitions through checkout from start to finish'
    end
  end
end
