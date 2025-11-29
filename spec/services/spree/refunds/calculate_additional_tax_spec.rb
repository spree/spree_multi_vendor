RSpec.describe Spree::Refunds::CalculateAdditionalTax do
  subject(:calculate_additional_tax) { described_class.call(refund: refund).value }

  let(:refund) { create(:refund, amount: 100, payment: order.payments.first, reimbursement: reimbursement) }

  let!(:order) { create(:vendor_shipped_order, without_line_items: true) }
  let!(:line_items) do
    [
      create(:vendor_line_item, order: order, price: 10, quantity: 2),
      create(:vendor_line_item, order: order, price: 20, quantity: 3)
    ]
  end

  let(:shipment) { order.shipments[0] }

  let(:reimbursement) { nil }
  let(:currency) { refund.currency }

  let!(:tax_adjustment_1) { create(:tax_adjustment, adjustable: line_items[0], order: order, amount: 2) }
  let!(:tax_adjustment_2) { create(:tax_adjustment, adjustable: line_items[1], order: order, amount: 6) }

  context 'for a parent order' do
    let!(:order) { create(:shipped_order, without_line_items: true) }
    let!(:line_items) do
      [
        create(:line_item, order: order, price: 10, quantity: 2),
        create(:line_item, order: order, price: 20, quantity: 3)
      ]
    end

    it { is_expected.to eq(Spree::Money.new(0, currency: order.currency)) }
  end

  context 'with reimbursement' do
    let(:reimbursement) { create(:reimbursement, return_items_count: 2) }

    before do
      reimbursement.return_items[0].inventory_unit.update!(quantity: 1, line_item_id: line_items[0].id)
      reimbursement.return_items[1].inventory_unit.update!(quantity: 2, line_item_id: line_items[1].id)
    end

    it 'calculates the sales tax for returned items' do
      expect(calculate_additional_tax).to eq(Spree::Money.new(5.0, currency: currency))
    end
  end

  context 'without reimbursement' do
    before do
      order.line_items.reload
      order.shipments[0].update_column(:additional_tax_total, 3)
    end

    it 'calculates the sales tax for all items' do
      expect(calculate_additional_tax).to eq(Spree::Money.new(11.0, currency: currency))
    end
  end
end
