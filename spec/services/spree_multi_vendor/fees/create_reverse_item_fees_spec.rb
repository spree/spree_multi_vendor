require 'spec_helper'

RSpec.describe SpreeMultiVendor::Fees::CreateReverseItemFees do
  subject { described_class.new(line_item: line_item, inventory_unit: inventory_unit).call }

  let(:return_item) { create(:return_item) }
  let(:inventory_unit) { return_item.inventory_unit }
  let(:line_item) { inventory_unit.line_item }
  let(:item_price) { 50.0 }

  describe '#call' do
    let(:platform_fee_total) { 15.0 }

    before do
      line_item.order.update!(platform_fee_reverse_total: 8.5)
      line_item.update!(
        price: item_price,
        platform_fee_rate: 10.0,
        platform_fee_per_unit: 5.0,
        platform_fee_total: platform_fee_total,
        platform_fee_reverse_total: 8.5
      )

      inventory_unit.update!(quantity: 3)
    end

    it 'creates item reverse platform fee' do
      expect { subject }.to change { line_item.marketplace_commissions.count }.by(1)

      reverse_fee = line_item.marketplace_commissions.last

      expect(reverse_fee.amount).to eq 15.0
      expect(reverse_fee.label).to eq Spree::MarketplaceCommission::REVERSE_ITEM_LABEL
      expect(reverse_fee.rate).to eq 10.0

      expect(line_item.reload.platform_fee_reverse_total).to eq(23.5)
      expect(line_item.order.reload.platform_fee_reverse_total).to eq(23.5)
    end

    it 'does not adjust line item platform fee total' do
      subject
      expect(line_item.reload.platform_fee_total).to eq(15)
    end


    context 'if line item platform fee is zero' do
      let(:platform_fee_total) { 0 }

      it 'does not create reverse platform fee' do
        expect { subject }.not_to change { line_item.marketplace_commissions.count }
        expect(subject).to eq nil
      end
    end
  end
end
