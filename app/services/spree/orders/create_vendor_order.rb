module Spree
  module Orders
    class CreateVendorOrder
      prepend ::Spree::ServiceModule::Base

      def call(order:, vendor:, index:)
        ActiveRecord::Base.transaction do
          run :create_vendor_order
          run :assign_addresses
          run :move_line_items
          run :move_shipments
          run :create_marketplace_commissions
          run :recalculate_totals
          run :create_store_credit_payments
          run :create_payments
          run :mark_as_completed
          run :create_vendor_order_notification
          run :update_vendor_cache
        end
      end

      private

      def create_vendor_order(order:, vendor:, index:)
        vendor_order = ::Spree::Order.create(
          number: "#{order.number}-#{index}",
          parent: order,
          vendor: vendor,
          user: order.user,
          special_instructions: order.special_instructions,
          store: order.store,
          email: order.email,
          payment_state: order.payment_state,
          shipment_state: order.shipment_state,
          last_ip_address: order.last_ip_address,
          currency: order.currency
        )

        success(order: order, vendor: vendor, vendor_order: vendor_order, index: index)
      end

      def assign_addresses(order:, vendor:, vendor_order:, index:)
        vendor_order.update_columns(
          ship_address_id: order.ship_address_id,
          bill_address_id: order.bill_address_id
        )

        success(order: order, vendor: vendor, vendor_order: vendor_order.reload, index: index)
      end

      def move_line_items(order:, vendor:, vendor_order:, index:)
        order.line_items.with_vendor(vendor.id).each do |line_item|
          line_item.update_column(:order_id, vendor_order.id)
          line_item.adjustments.update_all(order_id: vendor_order.id)
          line_item.inventory_units.update_all(order_id: vendor_order.id)
        end

        success(order: order, vendor: vendor, vendor_order: vendor_order.reload, index: index)
      end

      def move_shipments(order:, vendor:, vendor_order:, index:)
        order.shipments.with_vendor(vendor.id).each do |s|
          s.update_columns(order_id: vendor_order.id, address_id: vendor_order.ship_address_id)
          s.adjustments.update_all(order_id: vendor_order.id)
        end

        success(order: order, vendor: vendor, vendor_order: vendor_order.reload, index: index)
      end

      def create_marketplace_commissions(order:, vendor:, vendor_order:, index:)
        ::SpreeMultiVendor::Fees::CreateAllItemsFees.new(order: vendor_order).call unless order.covered_by_store_credit?

        success(order: order, vendor: vendor, vendor_order: vendor_order.reload, index: index)
      end

      def recalculate_totals(order:, vendor:, vendor_order:, index:)
        vendor_order.update_with_updater!

        success(order: order, vendor: vendor, vendor_order: vendor_order.reload, index: index)
      end

      def create_store_credit_payments(order:, vendor:, vendor_order:, index:)
        payments = order.payments.store_credits.valid.completed
        payments.each do |payment|
          if order.covered_by_store_credit?
            amount = payment.amount * (vendor_order.total / order.total)
          else
            calculated_store_credit_result = SpreeMultiVendor::StoreCredits::CalculateVendorStoreCredit.call(
              item_total: vendor_order.item_total,
              order: order,
              store_credit_total: payment.amount
            )

            amount = calculated_store_credit_result.value
          end

          Spree::Payment.insert(
            {
              order_id: vendor_order.id,
              vendor_id: vendor.id,
              source_id: payment.source_id,
              source_type: payment.source_type,
              number: "#{payment.number}-#{index}",
              amount: amount,
              response_code: payment.response_code,
              payment_method_id: payment.payment_method_id,
              state: 'completed'
            }
          )
        end

        success(order: order, vendor: vendor, vendor_order: vendor_order.reload)
      end

      def create_payments(order:, vendor:, vendor_order:)
        payment = order.payments.not_store_credits.last
        return success(order: order, vendor: vendor, vendor_order: vendor_order) unless payment.present?

        Spree::Payment.create!(
          order: vendor_order,
          source: payment.source,
          amount: vendor_order.total_minus_store_credits,
          response_code: payment.response_code,
          payment_method: payment.payment_method,
          state: 'completed'
        )

        success(order: order, vendor: vendor, vendor_order: vendor_order.reload)
      end

      def mark_as_completed(order:, vendor:, vendor_order:)
        vendor_order.update(
          state: :complete,
          completed_at: order.completed_at
        )

        success(order: order, vendor: vendor, vendor_order: vendor_order.reload)
      end

      def create_vendor_order_notification(order:, vendor:, vendor_order:)
        vendor_order.deliver_vendor_order_notification_email

        success(vendor_order: vendor_order.reload, vendor: vendor)
      end

      def update_vendor_cache(vendor_order:, vendor:)
        vendor.sales_total = vendor.orders.complete.sum(:total)
        vendor.commission_total = vendor.orders.complete.sum(:platform_fee_total)&.abs
        vendor.save!

        success(vendor_order)
      end
    end
  end
end
