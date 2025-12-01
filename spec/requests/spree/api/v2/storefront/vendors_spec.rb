require 'spec_helper'

RSpec.describe 'API V2 Storefront Vendor Spec', type: :request do
  describe 'vendors#show' do
    let!(:vendor) { create(:approved_vendor, :with_logo, :with_cover_photo, about: 'About section') }
    let!(:product) { create(:product, vendor: vendor) }

    context 'with invalid vendor id' do
      before { get '/api/v2/storefront/vendors/vendor1' }

      it_behaves_like 'returns 404 HTTP status'
    end

    context 'with valid vendor id' do
      let(:response_data) { json_response['data'] }

      before { get "/api/v2/storefront/vendors/#{vendor.id}" }

      it_behaves_like 'returns 200 HTTP status'

      it 'returns vendor valid JSON response' do
        expect(response_data['id']).to eq(vendor.id.to_s)
        expect(response_data['type']).to eq('vendor')
        expect(response_data['attributes']).to include(
          'name' => vendor.name,
          'email' => vendor.contact_person_email,
          'about_us' => 'About section'
        )
        expect(response_data['attributes']['logo_url']).to be_present
        expect(response_data['attributes']['cover_photo_url']).to be_present
      end
    end

    context 'with vendor slug' do
      before { get "/api/v2/storefront/vendors/#{vendor.slug}" }

      it_behaves_like 'returns 200 HTTP status'
    end
  end

  describe 'vendors#index' do
    let!(:vendor) { create(:approved_vendor, :with_logo, :with_cover_photo, about: 'About section') }
    let!(:vendors) { create_list(:approved_vendor, 10) }
    let(:params) { {} }

    before { get '/api/v2/storefront/vendors', params: params }

    context 'returns vendors list' do
      let(:vendor_data) { json_response['data'].find { |data| data['id'] == vendor.id.to_s } }

      it_behaves_like 'returns 200 HTTP status'

      it 'with all vendors' do
        expect(json_response['data'].count).to eq (11)
      end

      it 'returns vendor valid JSON response' do
        expect(vendor_data['id']).to eq(vendor.id.to_s)
        expect(vendor_data['type']).to eq('vendor')
        expect(vendor_data['attributes']).to include(
          'name' => vendor.name,
          'email' => vendor.contact_person_email,
          'about_us' => 'About section'
        )
        expect(vendor_data['attributes']['logo_url']).to be_present
        expect(vendor_data['attributes']['cover_photo_url']).to be_present

        expect(vendor_data['relationships']['metafields']).to eq('data' => [])
        expect(vendor_data['relationships']['policies']).to eq(
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
end
