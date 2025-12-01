require 'spec_helper'

RSpec.describe SpreeMultiVendor::Fees::CreateReverseOrderFee do
  describe '#call' do
    subject { described_class.new(order: order, refunded_amount: refunded_amount).call }

    let(:order) { create(:order, platform_fee_total: 20) }
    let(:refunded_amount) { 10 }

    before do
      order.update!(
        total: 100.0,
        platform_fee_reverse_total: 3.5
      )
    end

    it 'creates reversed platform fee linked to the order' do
      expect { subject }.to change { order.marketplace_commissions.count }.by(1)

      expect(subject.amount).to eq(2.0)
      expect(order.reload.platform_fee_reverse_total).to eq(5.5)
    end

    it 'does not adjust line item platform fee total' do
      subject
      expect(order.platform_fee_total).to eq(20)
    end

    context 'if order platform fee is 0.0' do
      let(:order) { create(:order, platform_fee_total: 0.0) }

      it 'does not create reverse platform fee' do
        expect { subject }.not_to change { order.marketplace_commissions.count }
        expect(subject).to eq nil
      end
    end

    context 'when trying to refund more commission than allowed' do
      before do
        order.update!(platform_fee_reverse_total: 18.5)
      end

      it 'creates reversed platform fee linked to the order' do
        expect { subject }.to change { order.marketplace_commissions.count }.by(1)

        expect(subject.amount).to eq(1.5)
        expect(order.reload.platform_fee_reverse_total).to eq(20.0)
      end
    end
  end
end
