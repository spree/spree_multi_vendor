module SpreeMultiVendor
  module StoreCredits
    class CalculateVendorStoreCredit
      prepend ::Spree::ServiceModule::Base

      def call(item_total:, order:, store_credit_total: nil)
        parent_order = order.parent || order
        store_credit_total ||= parent_order.total_applied_store_credit

        return success(0.to_d) if store_credit_total.zero?

        vendor_store_credit = ((item_total / parent_order.item_total) * store_credit_total).round(2, BigDecimal::ROUND_HALF_UP)

        success(vendor_store_credit)
      end
    end
  end
end
