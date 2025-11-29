require 'spec_helper'

RSpec.describe SpreeMultiVendor::Fees::CreateItemFee do
  subject { described_class.new(item: line_item, rate: rate).call }

  let(:line_item) { create(:line_item, price: 99.99, quantity: 2) }
  let(:rate) { nil }
  let(:vendor) { create(:vendor, platform_fee: vendor_platform_fee) }
  let(:vendor_platform_fee) { 10 }
  let(:product_platform_fee) { 5 }

  before do
    line_item.product.update!(vendor: vendor)
    line_item.update!(vendor: vendor)

    allow(vendor).to receive(:payment_gateway_connected?).and_return true
  end

  describe '#call' do
    context 'if rate is not passed' do
      context 'if product platform fee is present' do
        before do
          line_item.product.update!(platform_fee: product_platform_fee)
        end

        it 'calculates rate based on product platform fee and creates a fee' do
          expect { subject }.to change { line_item.marketplace_commissions.count }.by(1)
          expect(subject.amount).to eq(10)
          expect(subject.label).to eq Spree::MarketplaceCommission::ITEM_LABEL
          expect(subject.feeable).to eq(line_item)
        end

        it 'sets line item platform fee per unit correctly' do
          subject

          expect(line_item.reload.platform_fee_per_unit).to eq(5)
        end

        it 'sets line item platform fee total correctly' do
          subject

          expect(line_item.reload.platform_fee_total).to eq(10)
        end

        it 'sets line item platform fee rate correctly' do
          subject

          expect(line_item.reload.platform_fee_rate).to eq product_platform_fee
        end
      end

      context 'if product platform fee is not present' do
        it 'calculates rate based on vendor platform fee and creates a fee' do
          expect { subject }.to change { line_item.marketplace_commissions.count }.by(1)
          expect(subject.amount).to eq(20)
          expect(subject.label).to eq Spree::MarketplaceCommission::ITEM_LABEL
          expect(subject.feeable).to eq(line_item)
        end

        it 'sets line item platform fee per unit correctly' do
          subject

          expect(line_item.reload.platform_fee_per_unit).to eq(10)
        end

        it 'sets line item platform fee total correctly' do
          subject

          expect(line_item.reload.platform_fee_total).to eq(20)
        end

        it 'sets line item platform fee rate correctly' do
          subject

          expect(line_item.reload.platform_fee_rate).to eq vendor_platform_fee
        end
      end

      context 'if rate is zero' do
        before do
          line_item.product.update!(platform_fee: 0.0)
        end

        it 'does not create a platform fee' do
          expect { subject }.not_to change { line_item.marketplace_commissions.count }
        end

        it 'sets line item platform fee per unit correctly' do
          subject

          expect(line_item.reload.platform_fee_per_unit).to eq 0.0
        end

        it 'sets line item platform fee total correctly' do
          subject

          expect(line_item.reload.platform_fee_total).to eq 0.0
        end

        it 'sets line item platform fee rate correctly' do
          subject

          expect(line_item.reload.platform_fee_rate).to eq nil
        end
      end
    end

    context 'if custom rate is passed' do
      let(:rate) { 50.0 }

      it 'calculates rate based on custom_rate and creates a fee' do
        expect { subject }.to change { line_item.marketplace_commissions.count }.by(1)
        expect(subject.amount).to eq(100)
        expect(subject.label).to eq Spree::MarketplaceCommission::ITEM_LABEL
        expect(subject.feeable).to eq(line_item)
      end

      it 'sets line item platform fee per unit correctly' do
        subject

        expect(line_item.reload.platform_fee_per_unit).to eq(50)
      end

      it 'sets line item platform fee total correctly' do
        subject

        expect(line_item.platform_fee_total).to eq(100)
      end

      it 'sets line item platform fee rate correctly' do
        subject

        expect(line_item.platform_fee_rate).to eq(rate)
      end
    end
  end
end
