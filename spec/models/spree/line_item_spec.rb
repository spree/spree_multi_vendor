require 'spec_helper'

RSpec.describe Spree::LineItem, type: :model do
  context 'vendorized line item' do
    it 'assigns vendor from product' do
      product = create(:product_in_stock, vendor: create(:approved_vendor))
      line_item = create(:line_item, product: product)
      expect(line_item.vendor).to eq(product.vendor)
    end
  end

  context 'scope' do
    context 'platform_feeable' do
      subject { described_class.platform_feeable }

      let(:product) { create(:product_in_stock, vendor: vendor) }
      let(:vendor) { create(:approved_vendor) }
      let(:line_item) { create(:line_item, product: product) }

      before do
        line_item.update_column(:pre_tax_amount, pre_tax_amount)
      end

      context 'if item belongs to the vendor and has positive pre_tax_amount' do
        let(:pre_tax_amount) { 1.0 }

        it 'returns an item' do
          expect(subject).to eq [line_item]
        end
      end

      context 'if item belongs to the vendor, but has zero pretax_amount' do
        let(:pre_tax_amount) { 0.0 }

        it 'does not return the item' do
          expect(subject).to be_empty
        end
      end

      context 'if does not belong to the vendor, but has positive pretax_amount' do
        let(:pre_tax_amount) { 1.0 }
        let(:vendor) { nil }

        it 'does not return the item' do
          expect(subject).to be_empty
        end
      end
    end
  end
end
