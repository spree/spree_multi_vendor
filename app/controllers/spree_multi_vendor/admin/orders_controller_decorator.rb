module SpreeMultiVendor
  module Admin
    module OrdersControllerDecorator
      def self.prepended(base)
        base.before_action :load_vendor, only: [:index]
        base.before_action :show_only_main_orders, only: :index
      end

      private

      def load_order_items
        super

        @line_items = @order.all_line_items.includes(variant: [:product, :option_values])
        @shipments = @order.all_shipments.includes(
          :inventory_units, :selected_shipping_rate, :vendor,
          order: :vendor, shipping_rates: [:shipping_method, :tax_rate]
        ).order(:created_at)

        @suborders = @order.vendor_orders.includes(:vendor) if @order.splitted?
        @customer_returns = @order.all_customer_returns
      end

      # for marketplace operators we should show the main orders, not vendor sub-orders
      def show_only_main_orders
        return if current_vendor.present?

        params[:q] ||= {}
        params[:q][:without_vendor] = true
      end
    end
  end
end

Spree::Admin::OrdersController.prepend(SpreeMultiVendor::Admin::OrdersControllerDecorator)
