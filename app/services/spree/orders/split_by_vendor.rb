module Spree
  module Orders
    class SplitByVendor
      prepend ::Spree::ServiceModule::Base

      def call(order:)
        ActiveRecord::Base.transaction do
          run :check_if_parent_order
          run :check_if_already_created
          run :create_vendor_orders
          run :mark_order_as_splitted
        end
      end

      private

      def check_if_parent_order(order:)
        return failure(order) unless order.parent_order?

        success(order: order)
      end

      def check_if_already_created(order:)
        return failure(order) if order.vendor_orders.count == order.vendors.count

        success(order: order)
      end

      def create_vendor_orders(order:)
        order.vendors.where.not(id: order.vendor_orders.pluck(:vendor_id)).uniq.each_with_index do |vendor, index|
          Spree::Orders::CreateVendorOrder.call(order: order, vendor: vendor, index: index + 1)
        end

        success(order: order.reload)
      end

      def mark_order_as_splitted(order:)
        order.deliver_splitted_order_confirmation_email

        success(order: order)
      end
    end
  end
end
