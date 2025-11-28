module SpreeMultiVendor
  module Admin
    module OrdersHelperDecorator
      def order_summary_tax_lines_additional(order)
        line_item_taxes = order.suborder? ? [] : order.all_line_item_adjustments.tax
        line_item_taxes = line_item_taxes.map { |tax_adjustment| map_to_tax_line(tax_adjustment) }

        shipment_taxes = order.suborder? ? [] : order.all_shipment_adjustments.tax
        shipment_taxes = shipment_taxes.map { |tax_adjustment| map_to_tax_line(tax_adjustment, for_shipment: true) }

        line_item_taxes + shipment_taxes
      end

      def marketplace_commission_on_vendor_orders?(order)
        order.splitted? && order.vendor_order_marketplace_commissions.any?
      end

      def order_summary_marketplace_commissions(order)
        marketplace_commission_on_vendor_orders?(order) ? order.vendor_order_marketplace_commissions : order.marketplace_commissions
      end

      def order_summary_marketplace_commission_money(order)
        if marketplace_commission_on_vendor_orders?(order)
          order.vendor_orders.sum(Spree::Money.new(0, currency: order.currency)) do |vendor_order|
            calculate_marketplace_commission_total(vendor_order)
          end
        else
          calculate_marketplace_commission_total(order)
        end
      end

      private

      def calculate_marketplace_commission_total(order)
        order.platform_fee_total_money.abs - order.platform_fee_reverse_total_money.abs
      end
    end
  end
end

Spree::Admin::OrdersHelper.prepend(SpreeMultiVendor::Admin::OrdersHelperDecorator)
