module SpreeMultiVendor
  module Core
    module ControllerHelpers
      module OrderDecorator
        def user_orders_scope
          try_spree_current_user.orders.
            without_vendor.
            incomplete.
            not_canceled.
            where.not(id: current_order.id).
            where(store_id: current_store.id)
        end
      end
    end
  end
end

Spree::Core::ControllerHelpers::Order.prepend(SpreeMultiVendor::Core::ControllerHelpers::OrderDecorator)
