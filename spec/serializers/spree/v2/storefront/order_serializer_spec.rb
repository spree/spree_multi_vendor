require 'spec_helper'

describe Spree::V2::Storefront::OrderSerializer do
  include_context 'API v2 serializers params'

  subject { described_class.new(order).serializable_hash }

  let!(:parent_order) { create(:order, state: 'complete', completed_at: Time.current, store: store, parent: nil, vendor: nil) }
  let!(:vendor_order) { create(:vendor_order_with_line_items, store: store, parent: parent_order) }

  describe 'associations' do
    describe '#line_items' do
      context 'for parent order' do
        let(:order) { parent_order }

        it 'returns all line items' do
          expect(subject[:data][:relationships][:line_items][:data].count).to eq 1
          expect(subject[:data][:relationships][:line_items][:data][0][:id]).to eq vendor_order.line_items.take.id.to_s
        end
      end

      context 'for vendor order' do
        let(:order) { vendor_order }

        it 'returns all line items' do
          expect(subject[:data][:relationships][:line_items][:data].count).to eq 1
          expect(subject[:data][:relationships][:line_items][:data][0][:id]).to eq vendor_order.line_items.take.id.to_s
        end
      end
    end

    describe '#variants' do
      context 'for parent order' do
        let(:order) { parent_order }

        it 'returns all variants' do
          expect(subject[:data][:relationships][:variants][:data].count).to eq 1
          expect(subject[:data][:relationships][:variants][:data][0][:id]).to eq vendor_order.variants.take.id.to_s
        end
      end

      context 'for vendor order' do
        let(:order) { vendor_order }

        it 'returns all variants' do
          expect(subject[:data][:relationships][:variants][:data].count).to eq 1
          expect(subject[:data][:relationships][:variants][:data][0][:id]).to eq vendor_order.variants.take.id.to_s
        end
      end
    end

    describe '#shipments' do
      context 'for parent order' do
        let(:order) { parent_order }

        it 'returns all shipments' do
          expect(subject[:data][:relationships][:shipments][:data].count).to eq 1
          expect(subject[:data][:relationships][:shipments][:data][0][:id]).to eq vendor_order.shipments.take.id.to_s
        end
      end

      context 'for vendor order' do
        let(:order) { vendor_order }

        it 'returns all shipments' do
          expect(subject[:data][:relationships][:shipments][:data].count).to eq 1
          expect(subject[:data][:relationships][:shipments][:data][0][:id]).to eq vendor_order.shipments.take.id.to_s
        end
      end
    end

    describe '#vendors' do
      context 'for parent order' do
        let(:order) { parent_order }

        it 'returns all vendors' do
          expect(subject[:data][:relationships][:vendors][:data].count).to eq 1
          expect(subject[:data][:relationships][:vendors][:data][0][:id]).to eq vendor_order.vendors.take.id.to_s
        end
      end

      context 'for vendor order' do
        let(:order) { vendor_order }

        it 'returns all vendors' do
          expect(subject[:data][:relationships][:vendors][:data].count).to eq 1
          expect(subject[:data][:relationships][:vendors][:data][0][:id]).to eq vendor_order.vendors.take.id.to_s
        end
      end
    end
  end
end
