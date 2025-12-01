module SpreeMultiVendor
  module Orders
    module FindCompleteDecorator
      def scope
        user? ? user.orders.without_vendor.complete.includes(order_includes) : Spree::Order.without_vendor.complete.includes(order_includes)
      end
    end
  end
end

Spree::Orders::FindComplete.prepend(SpreeMultiVendor::Orders::FindCompleteDecorator)
