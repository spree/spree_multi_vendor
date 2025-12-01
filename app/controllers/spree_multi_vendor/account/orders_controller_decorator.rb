module SpreeMultiVendor
  module Account
    module OrdersControllerDecorator
      private

      def load_order_details
        @order = orders_scope.find_by!(number: params[:id])
        @shipments = @order.all_shipments.includes(:stock_location, :address, selected_shipping_rate: :shipping_method, inventory_units: :line_item)
      end
    end
  end
end

if defined?(Spree::Account::OrdersController)
  Spree::Account::OrdersController.prepend(SpreeMultiVendor::Account::OrdersControllerDecorator)
end
