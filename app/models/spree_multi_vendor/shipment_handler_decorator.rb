module SpreeMultiVendor
  module ShipmentHandlerDecorator
    def perform
      super
      order.shipment_shipped
    end

    private

    def order
      @shipment.order
    end

    def store
      @shipment.order.store
    end

    def update_order_shipment_state
      super

      @order = @shipment.order
      @parent_order = @order.parent

      return if @parent_order.nil?

      new_state_for_parent_order = ::Spree::OrderUpdater.new(@parent_order).update_shipment_state
      @parent_order.update_columns(shipment_state: new_state_for_parent_order, updated_at: Time.current)
    end
  end
end

Spree::ShipmentHandler.prepend(SpreeMultiVendor::ShipmentHandlerDecorator)
