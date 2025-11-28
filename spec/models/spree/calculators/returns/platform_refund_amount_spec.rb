require 'spec_helper'

RSpec.describe Spree::Calculators::Returns::PlatformRefundAmount do
  let(:calculator) { described_class.new }

  describe '#compute' do
    subject { calculator.compute(return_item) }

    let(:return_item) { create(:return_item, inventory_unit: inventory_unit) }
    let(:inventory_unit) { create(:inventory_unit, quantity: return_quantity, line_item: line_item) }

    let(:line_item) do
      create(:line_item,
             quantity: 3,
             price: 100,
             platform_fee_per_unit: 10.12)
    end

    let(:exchange_variant) { nil }
    let(:return_quantity) { 3 }
    let(:promo_total) { 0 }
    let(:included_tax_total) { 0 }

    before do
      line_item.update!(
        promo_total: promo_total,
        included_tax_total: included_tax_total
      )
    end

    context 'for a full refund' do
      it { is_expected.to eq(269.64) }

      context 'when discounted' do
        let(:promo_total) { 9.24 }

        it { is_expected.to eq(260.4) }
      end

      context 'when there is included tax' do
        let(:included_tax_total) { 9.24 }

        it { is_expected.to eq(260.4) }
      end

      context 'when both discounted and there is included tax' do
        let(:promo_total) { 9.24 }
        let(:included_tax_total) { 9.24 }

        it { is_expected.to eq(251.16) }
      end

      context 'when there is no platform fee' do
        before do
          line_item.update!(
            platform_fee_per_unit: 0.00,
            platform_fee_total: 0.00,
            platform_fee_rate: 0.00
          )
        end

        it { is_expected.to eq(300.00) }
      end
    end

    context 'for a partial refund' do
      let(:return_quantity) { 2 }

      it { is_expected.to eq(179.76) }

      context 'when discounted' do
        let(:promo_total) { 9.24 }

        it { is_expected.to eq(173.6) }
      end

      context 'when there is included tax' do
        let(:included_tax_total) { 9.24 }

        it { is_expected.to eq(173.6) }
      end

      context 'when both discounted and there is included tax' do
        let(:promo_total) { 9.24 }
        let(:included_tax_total) { 9.24 }

        it { is_expected.to eq(167.44) }
      end

      context 'when there is no platform fee' do
        before do
          line_item.update!(
            platform_fee_per_unit: 0.00,
            platform_fee_total: 0.00,
            platform_fee_rate: 0.00
          )
        end

        it { is_expected.to eq(200.00) }
      end
    end

    context 'when return is an exchange' do
      let(:return_item) { double(:return_item, exchange_requested?: true) }

      it { is_expected.to eq(0) }
    end
  end
end
