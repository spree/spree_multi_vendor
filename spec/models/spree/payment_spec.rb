describe Spree::Payment, type: :model do
  context 'vendorized payment' do
    it 'assigns vendor from order' do
      order = create(:vendor_order_with_totals, total: 100)
      payment = create(:payment, order: order)
      expect(payment.vendor).to eq(order.vendor)
    end
  end

  describe 'can_credit?' do
    subject { payment.can_credit? }

    let(:payment) { create(:payment, order: order, amount: 10) }

    before do
      allow(payment).to receive(:credit_allowed).and_return(credit_allowed)
    end

    context 'when the payment is not on a vendor order' do
      let(:order) { create(:order, total: 100) }

      context 'when credit allowed is greater than 0' do
        let(:credit_allowed) { 10 }
        it { is_expected.to be(true) }
      end

      context 'when credit allowed is 0' do
        let(:credit_allowed) { 0 }
        it { is_expected.to be(false) }
      end

      context 'when the payment is a store credit' do
        let(:payment) { create(:store_credit_payment, order: order, amount: 10) }

        context 'when the credit allowed is greater than 0' do
          let(:credit_allowed) { 10 }
          it { is_expected.to be(true) }
        end

        context 'when the credit allowed is 0' do
          let(:credit_allowed) { 0 }
          it { is_expected.to be(false) }
        end
      end
    end

    context 'when the payment is on a vendor order' do
      let(:order) { create(:vendor_order, total: 100) }

      context 'when credit allowed is greater than 0' do
        let(:credit_allowed) { 10 }
        it { is_expected.to be(true) }
      end

      context 'when credit allowed is 0' do
        let(:credit_allowed) { 0 }
        it { is_expected.to be(false) }
      end

      context 'when the payment is a store credit' do
        let(:payment) { create(:store_credit_payment, order: order, amount: 10) }

        context 'when the credit allowed is greater than 0' do
          let(:credit_allowed) { 10 }
          it { is_expected.to be(false) }
        end

        context 'when the credit allowed is 0' do
          let(:credit_allowed) { 0 }
          it { is_expected.to be(false) }
        end
      end
    end
  end
end
