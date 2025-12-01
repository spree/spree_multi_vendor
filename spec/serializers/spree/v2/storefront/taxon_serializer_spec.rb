require 'spec_helper'

RSpec.describe Spree::V2::Storefront::TaxonSerializer do
  include_context 'API v2 serializers params'

  subject { described_class.new(taxon.reload, params: serializer_params.merge({ include_products: include_products })).serializable_hash }

  let(:taxon) { create(:taxon) }

  let(:include_products) { false }

  it { expect(subject).to be_kind_of(Hash) }

  describe 'products' do
    let(:include_products) { true }

    let!(:active_product_from_approved_vendor) { create(:product, taxons: [taxon], vendor: create(:vendor)) }
    let!(:active_product_from_unapproved_vendor) { create(:product, taxons: [taxon], vendor: create(:vendor, state: :onboarding)) }
    let!(:inactive_product_from_approved_vendor) { create(:product, taxons: [taxon], vendor: create(:vendor), status: :draft) }
    let!(:inactive_product_from_unapproved_vendor) do
      create(:product, taxons: [taxon], vendor: create(:vendor, state: :onboarding), status: :draft)
    end
    let!(:active_product_without_vendor) { create(:product, taxons: [taxon], vendor: nil) }
    let!(:inactive_product_without_vendor) { create(:product, taxons: [taxon], vendor: nil, status: :draft) }

    it 'returns all products' do
      expect(subject[:data][:relationships][:products][:data].count).to eq(6)
      expect(subject[:data][:relationships][:products][:data]).to match_array(
        [
          { type: :product, id: active_product_from_approved_vendor.id.to_s },
          { type: :product, id: active_product_from_unapproved_vendor.id.to_s },
          { type: :product, id: inactive_product_from_approved_vendor.id.to_s },
          { type: :product, id: inactive_product_from_unapproved_vendor.id.to_s },
          { type: :product, id: active_product_without_vendor.id.to_s },
          { type: :product, id: inactive_product_without_vendor.id.to_s }
        ]
      )
    end
  end

  describe 'has_products' do
    context 'when the taxon has products' do
      let!(:product) { create(:product, taxons: [taxon]) }

      it 'returns true' do
        expect(subject[:data][:attributes][:has_products]).to be true
      end
    end

    context 'when the taxon does not have products' do
      it 'returns false' do
        expect(subject[:data][:attributes][:has_products]).to be false
      end
    end
  end
end
