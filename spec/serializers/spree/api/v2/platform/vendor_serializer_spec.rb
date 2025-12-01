require 'spec_helper'

describe Spree::Api::V2::Platform::VendorSerializer do
  include_context 'API v2 serializers params'

  subject { described_class.new(vendor, params: serializer_params).serializable_hash }

  let(:vendor) { create(:vendor) }

  it 'returns the vendor name' do
    expect(subject.dig(:data, :attributes, :name)).to eq(vendor.name)
  end

  it 'returns the slug' do
    expect(subject.dig(:data, :attributes, :slug)).to eq(vendor.slug)
  end

  it 'returns the contact person email' do
    expect(subject.dig(:data, :attributes, :contact_person_email)).to eq(vendor.contact_person_email)
  end

  it 'returns the public metadata' do
    expect(subject.dig(:data, :attributes, :public_metadata)).to eq(vendor.public_metadata)
  end
end