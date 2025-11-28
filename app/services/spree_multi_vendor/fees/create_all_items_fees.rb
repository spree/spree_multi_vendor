module SpreeMultiVendor
  module Fees
    class CreateAllItemsFees
      def initialize(order:)
        @order = order
      end

      def call
        vendor_line_items = order.reload.line_items.platform_feeable.includes(:product, :vendor)
        items_fees = vendor_line_items.map { |item| SpreeMultiVendor::Fees::CreateItemFee.new(item: item).call }

        items_fees.compact
      end

      private

      attr_reader :order
    end
  end
end
