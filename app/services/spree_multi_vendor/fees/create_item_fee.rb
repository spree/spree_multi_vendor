module SpreeMultiVendor
  module Fees
    class CreateItemFee
      def initialize(item:, rate: nil)
        @item = item
        @rate = rate
      end

      def call
        calculations = CalculateItemFee.call(item: item, rate: rate)
        return if calculations.failure?

        platform_fee = Spree::MarketplaceCommission.create!(
          amount: calculations.value[:fee_total],
          order: item.order,
          feeable: item,
          label: Spree::MarketplaceCommission::ITEM_LABEL,
          rate: calculations.value[:rate],
          active: true
        )

        item.update_columns(
          platform_fee_per_unit: calculations.value[:fee_per_unit],
          platform_fee_total: calculations.value[:fee_total],
          platform_fee_rate: calculations.value[:rate]
        )

        platform_fee
      end

      private

      attr_reader :item, :rate
    end
  end
end
