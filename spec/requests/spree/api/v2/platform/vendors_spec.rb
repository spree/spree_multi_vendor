require 'spec_helper'

RSpec.describe 'API V2 Platform Vendors Spec' do
  include_context 'Platform API v2'
  let(:bearer_token) { { 'Authorization' => valid_authorization } }
  let!(:vendor) { create(:vendor) }

  describe 'GET show' do
    it 'should return vendor' do
      get "/api/v2/platform/vendors/#{vendor.id}", headers: bearer_token

      expect(response.status).to eq(200)

      expect(json_response['data']['id']).to eq(vendor.id.to_s)
      expect(json_response['data']['attributes']['name']).to eq(vendor.name)
      expect(json_response['data']['attributes']['about_us']).to eq(vendor.about.to_plain_text)

      expect(json_response['data']['relationships']['metafields']).to eq('data' => [])
      expect(json_response['data']['relationships']['policies']).to eq(
        'data' => [
          {
            'id' => vendor.policies.first.id.to_s,
            'type' => 'policy'
          }
        ]
      )
    end
  end
end
