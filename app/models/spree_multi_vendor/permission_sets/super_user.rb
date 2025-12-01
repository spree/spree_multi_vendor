module SpreeMultiVendor
  module PermissionSets
    class SuperUser < Spree::PermissionSets::Base
      def activate!
        # reset stock permissions
        cannot :manage, Spree::StockItem
        cannot :manage, Spree::StockLocation
        cannot :manage, Spree::StockMovement
        can :read, Spree::StockItem
        can :read, Spree::StockLocation
        can :read, Spree::StockMovement
        # disable
        can :manage, Spree::StockItem, variant: { product: { vendor_id: nil } }
        can :manage, Spree::StockLocation, vendor_id: nil
        can :manage, Spree::StockMovement, stock_item: { variant: { product: { vendor_id: nil } } }
        can :create, Spree::StockMovement
        can :create, Spree::StockItem
        can :create, Spree::StockLocation

        # orders
        cannot :update_customer, Spree::Order
        can :update_customer, Spree::Order do |o|
          !o.splitted? && !o.shipped? && o.vendors.empty? && !o.canceled?
        end
        cannot :update_addresses, Spree::Order
        can :update_addresses, Spree::Order do |o|
          !o.shipped? && !o.canceled?
        end
        cannot %i[fire], Spree::Order, state: 'splitted'
        can :resend, Spree::Order, state: 'splitted'
        cannot :refund, Spree::Order, &:splitted?
        cannot :cancel, Spree::Order
        can :cancel, Spree::Order, &:allow_cancel?
        cannot :create, Spree::Adjustment, adjustable: { state: 'splitted' }
        cannot :manage, Spree::Adjustment, adjustable: { state: 'splitted' }
        cannot :manage, Spree::LineItem
        can :manage, Spree::LineItem, { vendor_id: nil }

        cannot :update, Spree::LineItem, order: { state: 'splitted' }
        cannot :create, Spree::LineItem, order: { state: ['splitted', 'canceled'] }

        cannot :split, Spree::Shipment
        can :split, Spree::Shipment, vendor_id: nil
        cannot :delete, Spree::Shipment
        can :delete, Spree::Shipment, vendor_id: nil
        cannot :split, Spree::Shipment, state: ['shipped', 'canceled']
        can :edit, Spree::Order
        can :read, Spree::Order

        # product catalog management

        cannot :create, Spree::Refund do |refund|
          refund.order&.splitted?
        end
        cannot :edit, Spree::Refund do |refund|
          payment_method = refund.payment.payment_method
          payment_method.respond_to?(:stripe?) && payment_method.stripe?
        end

        can :manage, Spree::ShippingMethod, vendor_id: nil
        can :manage, Spree::ShippingCategory

        # we need to protect default stock location
        cannot :delete, Spree::StockLocation, default: true

        # returns
        can :manage, Spree::ReturnAuthorization
        cannot :manage, Spree::ReturnAuthorization, order: { completed_at: nil }
        cannot :manage, Spree::ReturnAuthorization, order: { state: ['splitted', 'canceled'] }

        # we need to prohibit opton types edit if product is synced from shopify/woo/etc
        cannot :manage_option_types, Spree::Product
        can :manage_option_types, Spree::Product, { vendor_id: nil }
        cannot :destroy, Spree::Product do |product|
          product.external?
        end

        # allow to clone 1st party products
        cannot :clone, Spree::Product
        can :clone, Spree::Product do |product|
          !product.external? && product.vendor.nil?
        end

        # protect default vendor role
        cannot [:edit, :update,:delete], Spree::Role, name: Spree::Vendor::DEFAULT_VENDOR_ROLE
      end
    end
  end
end
