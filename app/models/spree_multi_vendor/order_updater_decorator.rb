module SpreeMultiVendor
  module OrderUpdaterDecorator
    def update_adjustment_total
      recalculate_adjustments
      order.adjustment_total = line_items.sum(:adjustment_total) +
        shipments.sum(:adjustment_total) +
        adjustments.eligible.sum(:amount)

      order.included_tax_total = line_items.sum(:included_tax_total) + shipments.sum(:included_tax_total)
      order.additional_tax_total = line_items.sum(:additional_tax_total) + shipments.sum(:additional_tax_total)

      order.platform_fee_total = -line_items.sum(:platform_fee_total)

      order.promo_total = line_items.sum(:promo_total) +
        shipments.sum(:promo_total) +
        adjustments.promotion.eligible.sum(:amount)

      update_order_total
    end

    def persist_totals
      super
      order.update_column(:platform_fee_total, order.platform_fee_total)
    end

    # this override is needed for multi-vendor orders
    def update_shipment_state
      if order.backordered?
        order.shipment_state = 'backorder'
      else
        # get all the shipment states for this order
        shipment_states = order.splitted? ? order.all_shipments.reload.pluck(:state).uniq.compact : shipments.reload.states.uniq

        order.shipment_state = if shipment_states.size > 1
                                 if shipment_states.include?('shipped')
                                   'partial'
                                 elsif shipment_states.include?('pending')
                                   'pending'
                                 else
                                   'ready'
                                 end
                               else
                                 # will return nil if no shipments are found
                                 shipment_states.first
                                 # TODO: inventory unit states?
                                 # if order.shipment_state && order.inventory_units.where(shipment_id: nil).exists?
                                 #   shipments exist but there are unassigned inventory units
                                 #   order.shipment_state = 'partial'
                                 # end
                               end
      end

      order.state_changed('shipment') unless order.splitted?
      order.shipment_state
    end
  end
end

Spree::OrderUpdater.prepend(SpreeMultiVendor::OrderUpdaterDecorator)
