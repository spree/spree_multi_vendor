require 'spec_helper'

RSpec.describe SpreeMultiVendor::StoreCredits::CalculateVendorStoreCredit do
  subject(:calculate_vendor_store_credit) { described_class.call(item_total: item_total, order: order, store_credit_total: store_credit_total) }

  let(:result) { calculate_vendor_store_credit.value }
  let(:store_credit_total) { nil }

  let(:store) { Spree::Store.default }
  let(:vendors) { create_list(:vendor, 2) }

  let(:order) { create(:order, store: store) }

  let(:product1) { create(:product_in_stock, vendor: vendors[0], price: product1_price) }
  let(:product2) { create(:product_in_stock, vendor: vendors[1], price: product2_price) }

  let(:product1_price) { 40 }
  let(:product2_price) { 30 }

  before do
    create(:line_item, order: order, product: product1, price: product1_price, quantity: 2)
    create(:line_item, order: order, product: product2, price: product2_price, quantity: 4)

    order.update_with_updater!
  end

  context 'with store credit payment' do
    before do
      create(:store_credit_payment, order: order, amount: 60)
    end

    context 'for a partial item total' do
      let(:item_total) { 80 }

      it { is_expected.to be_success }

      it 'calculates vendor store credit proportionally' do
        # vendor_store_credit = (80 / 200) * 60 = 24
        expect(result).to eq(24)
      end
    end

    context 'when item total is zero' do
      let(:item_total) { 0 }

      it { is_expected.to be_success }

      it 'returns zero' do
        expect(result).to eq(0)
      end
    end
  end

  context 'with no store credit payment' do
    let(:item_total) { 80 }

    it { is_expected.to be_success }

    it 'returns zero' do
      expect(result).to eq(0)
    end
  end

  context 'when custom store credit total is passed' do
    let(:store_credit_total) { 40 }

    context 'for full item total' do
      let(:item_total) { 200 }

      it { is_expected.to be_success }

      it 'calculates vendor store credit using custom total' do
        # vendor_store_credit = (200 / 200) * 40 = 40
        expect(result).to eq(40)
      end
    end

    context 'for partial item total' do
      let(:item_total) { 80 }

      it { is_expected.to be_success }

      it 'calculates vendor store credit proportionally using custom total' do
        # vendor_store_credit = (80 / 200) * 40 = 16
        expect(result).to eq(16)
      end
    end

    context 'when custom store credit total is zero' do
      let(:item_total) { 80 }
      let(:store_credit_total) { 0 }

      it { is_expected.to be_success }

      it 'returns zero' do
        expect(result).to eq(0)
      end
    end
  end

  context 'when calculation results in many decimal places' do
    let(:product3) { create(:product_in_stock, vendor: vendors[1], price: product3_price) }
    let(:product3_price) { 33.33 }

    before do
      create(:line_item, order: order, product: product3, price: product3_price, quantity: 3)
      order.reload.update_with_updater!
    end

    let(:item_total) { 99.99 }
    let(:store_credit_total) { 17.89 }

    it 'rounds to 2 decimal places' do
      # vendor_store_credit = (99.99 / 299.99) * 17.89 = 5.96292...
      expect(result).to eq(5.96)
    end
  end
end
