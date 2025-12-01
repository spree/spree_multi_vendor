require 'spec_helper'

describe 'API V2 Platform Orders Spec' do
  include_context 'Platform API v2'
  let(:bearer_token) { { 'Authorization' => valid_authorization } }
  let!(:order) { create(:vendor_order) }

  describe 'get index' do
    it 'should return only parent orders' do
      get '/api/v2/platform/orders', headers: bearer_token

      expect(response.status).to eq(200)
      expect(json_response['data'].count).to eq(1)
      expect(json_response['data'].first['id']).to eq(order.parent.id.to_s)
      expect(json_response['data'].first['relationships']['vendor_orders']).to eq(
        { "data" => [{ "id" => order.id.to_s, "type" => "order" }] }
      )
    end
  end

  describe 'get show' do
    it 'should return order' do
      get "/api/v2/platform/orders/#{order.id}", headers: bearer_token

      expect(response.status).to eq(200)
      expect(json_response['data']['id']).to eq(order.id.to_s)
      expect(json_response['data']['relationships']['vendor_orders']).to be_nil
    end
  end
end
