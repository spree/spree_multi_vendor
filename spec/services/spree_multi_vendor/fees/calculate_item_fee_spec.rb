require 'spec_helper'

RSpec.describe SpreeMultiVendor::Fees::CalculateItemFee do
  let(:line_item) do
    create(:line_item,
           price: 99.99,
           quantity: 2,
           promo_total: 0.00,
           product: create(:product_in_stock, vendor: vendor),
           vendor: vendor)
  end
  let(:rate) { nil }
  let(:vendor) { create(:vendor, platform_fee: vendor_platform_fee) }
  let(:vendor_platform_fee) { 10 }
  let(:product_platform_fee) { 5 }

  before { allow(vendor).to receive(:payment_gateway_connected?).and_return true }

  describe '#call' do
    subject { described_class.call(item: line_item, rate: rate) }
    let(:result) { subject.value }

    context 'if rate is not passed' do
      context 'if product platform fee is present' do
        before { line_item.product.update!(platform_fee: product_platform_fee) }

        it 'sets line item platform fee per unit correctly' do
          expect(result[:fee_per_unit]).to eq 5
        end

        it 'sets line item platform fee total correctly' do
          expect(result[:fee_total]).to eq 10
        end

        it 'sets line item platform fee rate correctly' do
          expect(result[:rate]).to eq product_platform_fee
        end
      end

      context 'if product platform fee is not present, but vendor platform fee is present' do
        it 'sets line item platform fee per unit correctly' do
          expect(result[:fee_per_unit]).to eq 10
        end

        it 'sets line item platform fee total correctly' do
          expect(result[:fee_total]).to eq 20
        end

        it 'sets line item platform fee rate correctly' do
          expect(result[:rate]).to eq vendor_platform_fee
        end
      end

      context 'if rate is zero' do
        before { line_item.product.update!(platform_fee: 0.0) }

        it 'returns failure' do
          expect(subject.failure?).to be true
        end
      end
    end

    context 'if custom rate is passed' do
      before { subject }

      let(:rate) { 50.0 }

      it 'sets line item platform fee per unit correctly' do
        expect(result[:fee_per_unit]).to eq 50
      end

      it 'sets line item platform fee total correctly' do
        expect(result[:fee_total]).to eq 100
      end

      it 'sets line item platform fee rate correctly' do
        expect(result[:rate]).to eq rate
      end
    end

    context 'when line item is discounted' do
      before do
        line_item.update(promo_total: -10.0)
        line_item.reload
      end

      it 'sets line item platform fee per unit correctly' do
        expect(result[:fee_per_unit]).to eq 9.5
      end

      it 'sets line item platform fee total correctly' do
        expect(result[:fee_total]).to eq 19
      end

      it 'sets line item platform fee rate correctly' do
        expect(result[:rate]).to eq vendor_platform_fee
      end
    end

    context 'when store credit is applied to the order' do
      let(:store) { Spree::Store.default }
      let(:order) { create(:order, store: store) }

      let(:other_vendor) { create(:vendor, platform_fee: vendor_platform_fee) }

      let!(:line_item) { create(:line_item, order: order, product: product, price: 50, quantity: 2) }
      let!(:line_item2) { create(:line_item, order: order, product: product2, price: 10, quantity: 2) }
      let!(:line_item3) { create(:line_item, order: order, product: product3, price: 30, quantity: 1) }

      let(:product) { create(:product_in_stock, vendor: vendor, price: 50) }
      let(:product2) { create(:product_in_stock, vendor: vendor, price: 10) }
      let(:product3) { create(:product_in_stock, vendor: other_vendor, price: 30) }

      before do
        order.update_with_updater!
        create(:store_credit_payment, order: order, amount: 30)
      end

      it 'calculates store credit per unit correctly' do
        # store_credit_per_unit = (50 / 150) * 30 = 10
        expect(result[:store_credit_per_unit]).to eq(10)
      end

      it 'calculates fee per unit correctly after deducting store credit' do
        # feeable_amount = 50 - 10 (store_credit) = 40
        # fee_per_unit = 40 * 10% = 4
        expect(result[:fee_per_unit]).to eq(4)
      end

      it 'calculates fee total correctly' do
        # fee_total = 4 * 2 = 8
        expect(result[:fee_total]).to eq(8)
      end
    end
  end
end
