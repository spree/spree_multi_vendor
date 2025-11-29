require 'spec_helper'

describe Spree::V2::Storefront::VendorSerializer do
  include_context 'API v2 serializers params'

  subject { described_class.new(vendor, params: serializer_params.merge({ include_products: include_products })).serializable_hash }

  let(:vendor) do
    create(:vendor, about: "Click <a href=\"https://google.com\"><strong><em>here</em></strong></a>!")
  end

  let(:url_helpers) { Rails.application.routes.url_helpers }

  let(:include_products) { false }

  describe 'products' do
    let(:include_products) { true }

    let!(:active_product) { create(:product, vendor: vendor) }
    let!(:inactive_product) { create(:product, vendor: vendor, status: :draft) }

    it 'should return only products that are active' do
      expect(subject[:data][:relationships][:products][:data].count).to eq(1)
      expect(subject[:data][:relationships][:products][:data]).to match_array(
        [
          { type: :product, id: active_product.id.to_s },
        ]
      )
    end
  end

  it 'returns the plain text of the about section' do
    expect(subject[:data][:attributes][:about_us]).to eq("Click here!")
  end

  it 'returns the contact email' do
    expect(subject.dig(:data, :attributes, :email)).to eq(vendor.contact_person_email)
  end

  it 'returns the slug' do
    expect(subject.dig(:data, :attributes, :slug)).to eq(vendor.slug)
  end

  context 'with a logo' do
    let(:vendor) { create(:vendor, :with_logo) }

    it 'returns the logo url' do
      expect(subject.dig(:data, :attributes, :logo_url)).to eq(url_helpers.cdn_image_url(vendor.logo.attachment))
    end
  end

  context 'with a cover photo' do
    let(:vendor) { create(:vendor, :with_cover_photo) }

    it 'returns the cover photo url' do
      expect(subject.dig(:data, :attributes, :cover_photo_url)).to eq(url_helpers.cdn_image_url(vendor.cover_photo.attachment))
    end
  end

  context 'with metafields' do
    before do
      vendor.set_metafield('test.test', 'test')
    end

    it 'returns the metafields' do
      expect(subject.dig(:data, :relationships, :metafields, :data)).to contain_exactly(
        {
          type: :metafield,
          id: vendor.metafields.first.id.to_s
        }
      )
    end
  end
end
