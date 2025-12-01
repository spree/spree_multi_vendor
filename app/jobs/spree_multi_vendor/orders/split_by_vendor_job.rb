module SpreeMultiVendor
  module Orders
    class SplitByVendorJob < ::SpreeMultiVendor::BaseJob
      def perform(order_id)
        order = Spree::Order.find(order_id)
        Spree::Orders::SplitByVendor.call(order: order)
      end
    end
  end
end
