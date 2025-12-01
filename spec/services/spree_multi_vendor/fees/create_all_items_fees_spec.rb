require 'spec_helper'

RSpec.describe SpreeMultiVendor::Fees::CreateAllItemsFees do
  subject { described_class.new(order: order.reload).call }

  let!(:order) { create(:vendor_order_with_line_items, line_items_count: 3, vendor: vendor) }
  let(:vendor) { create(:vendor, platform_fee: vendor_platform_fee) }
  let(:vendor_platform_fee) { 10 }
  let(:product_platform_fee) { 5 }
  let(:fees_amount) { 15.0 }

  let(:line_item_1) { order.line_items.first }
  let(:line_item_2) { order.line_items.second }
  let(:line_item_3) { order.line_items.third }

  let(:fee_1) { subject.find { |fee| fee.feeable == line_item_1 } }
  let(:fee_2) { subject.find { |fee| fee.feeable == line_item_2 } }
  let(:fee_3) { subject.find { |fee| fee.feeable == line_item_3 } }

  describe '#call' do
    before do
      allow(vendor).to receive(:payment_gateway_connected?).and_return true

      order.line_items.update_all(vendor_id: vendor.id, price: 99.99)

      line_item_1.product.update!(vendor: vendor, platform_fee: product_platform_fee)
      line_item_2.product.update!(vendor: vendor)
      line_item_3.product.update!(vendor: vendor)
    end

    it 'creates application fee adjustments' do
      subject

      expect(fee_1.amount).to eq(5)
      expect(fee_1.label).to eq Spree::MarketplaceCommission::ITEM_LABEL
      expect(fee_1.rate).to eq product_platform_fee
      expect(fee_1.feeable.platform_fee_per_unit).to eq(5)
      expect(fee_1.feeable.platform_fee_total).to eq(5)

      expect(fee_2.amount).to eq(10)
      expect(fee_2.label).to eq Spree::MarketplaceCommission::ITEM_LABEL
      expect(fee_2.rate).to eq vendor_platform_fee
      expect(fee_2.feeable.platform_fee_per_unit).to eq(10)
      expect(fee_2.feeable.platform_fee_total).to eq(10)

      expect(fee_3.amount).to eq(10)
      expect(fee_3.label).to eq Spree::MarketplaceCommission::ITEM_LABEL
      expect(fee_3.rate).to eq vendor_platform_fee
      expect(fee_3.feeable.platform_fee_per_unit).to eq(10)
      expect(fee_3.feeable.platform_fee_total).to eq(10)
    end

    context 'for non vendorized items' do
      before do
        order.line_items.second.update_column(:vendor_id, nil)
      end

      it 'does not call CreateItemFee' do
        expect { subject }.to change(Spree::MarketplaceCommission, :count).by(2)

        expect(fee_1).to be_present
        expect(fee_2).to be_blank
        expect(fee_3).to be_present
      end
    end
  end
end
