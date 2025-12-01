module SpreeMultiVendor
  module PermissionSets
    class VendorUser < Spree::PermissionSets::Base
      def activate!
        @vendor_ids = user.vendors.ids

        return if @vendor_ids.empty?

        can :manage, Spree::Vendor, id: @vendor_ids
        cannot %i[delete approve reject suspend delete], Spree::Vendor

        can :read, Spree::Role, name: Spree::Vendor::DEFAULT_VENDOR_ROLE

        apply_asset_permissions
        apply_dashboard_permissions
        apply_classifications_permissions
        apply_order_permissions
        apply_import_permissions
        apply_option_type_permissions
        apply_price_permissions
        apply_product_option_type_permissions
        apply_product_permissions
        apply_shipment_permissions
        apply_shipping_methods_permissions
        apply_stock_permissions
        apply_stock_item_permissions
        apply_stock_location_permissions
        apply_stock_movement_permissions
        apply_variant_permissions
        apply_returns_permissions
        apply_reports_permissions
        apply_digital_permissions
        apply_taxons_permissions
        apply_export_permissions
        apply_import_permissions

        can :manage, :vendor_settings

        can :create, Spree::Invitation
        can :manage, Spree::Invitation, resource_type: 'Spree::Vendor', resource_id: @vendor_ids

        can [:read, :manage], Spree.admin_user_class, role_users: { resource_type: 'Spree::Vendor', resource_id: @vendor_ids }
        can :manage, Spree::RoleUser, resource_type: 'Spree::Vendor', resource_id: @vendor_ids

        can :manage, :profile

        cannot :mark_as_default, Spree::StockLocation

        cannot :manage, Spree::Policy
        can :manage, Spree::Policy, owner_type: 'Spree::Vendor', owner_id: @vendor_ids
        cannot :create, Spree::Policy
      end

      private

      def apply_asset_permissions
        can %i[new create], Spree::Asset

        can %i[manage modify], Spree::Asset, viewable_type: 'Spree::Variant', viewable_id: nil
        can %i[manage modify], Spree::Asset, viewable_type: 'Spree::Variant', viewable_id: Spree::Variant.with_vendor(@vendor_ids).ids
        can %i[manage modify], Spree::Asset, viewable_type: 'Spree::Vendor', viewable_id: @vendor_ids
      end

      def apply_dashboard_permissions
        can :manage, :dashboard
      end

      def apply_classifications_permissions
        can :manage, Spree::Classification, product: { vendor_id: @vendor_ids }
      end

      def apply_order_permissions
        can :manage, Spree::Order, { vendor_id: @vendor_ids }
        cannot :cancel, Spree::Order
        cannot :resend, Spree::Order
        cannot :create, Spree::Order
        cannot :update_customer, Spree::Order
        can :cancel, Spree::Order, { vendor_id: @vendor_ids }
      end

      def apply_import_permissions
      end

      def apply_option_type_permissions
        can :display, Spree::OptionType
        can :display, Spree::OptionValue
      end

      def apply_price_permissions
        can :create, Spree::Price
        can :manage, Spree::Price, variant: { product: { vendor_id: @vendor_ids } }
      end

      def apply_product_option_type_permissions
        can :manage,  Spree::ProductOptionType, product: { vendor_id: @vendor_ids }
        can :create,  Spree::ProductOptionType
        can :manage,  Spree::OptionValueVariant, variant: { product: { vendor_id: @vendor_ids } }
        can :create,  Spree::OptionValueVariant
      end

      def apply_product_permissions
        cannot :read, Spree::Product
        can :manage, Spree::Product, vendor_id: @vendor_ids
        cannot :manage_option_types, Spree::Product
        can :manage_option_types, Spree::Product, vendor_id: @vendor_ids
        can :create, Spree::Product
        cannot :activate, Spree::Product
        cannot :manage_tags, Spree::Product
        cannot :manage_labels, Spree::Product
        cannot :manage_commission, Spree::Product
        cannot %i[clone destroy], Spree::Product do |product|
          product.external_id.present?
        end
      end

      def apply_shipment_permissions
        can %i[manage ready ship cancel resume pend], Spree::Shipment, order: { vendor_id: @vendor_ids }
        cannot :split, Spree::Shipment
      end

      def apply_shipping_methods_permissions
        can :manage, Spree::ShippingMethod, vendor_id: @vendor_ids
        can :create, Spree::ShippingMethod
        cannot :manage, Spree::ShippingCategory
      end

      def apply_stock_permissions
        can :admin, Spree::Stock
      end

      def apply_stock_item_permissions
        can %i[create bulk_set_backorderable bulk_set_track_inventory], Spree::StockItem
        can %i[admin modify read toggle_backorderable manage], Spree::StockItem, variant: { product: { vendor_id: @vendor_ids } }
      end

      def apply_stock_location_permissions
        can :manage, Spree::StockLocation, vendor_id: @vendor_ids
        cannot :create, Spree::StockLocation
        cannot :destroy, Spree::StockLocation
      end

      def apply_stock_movement_permissions
        can :create, Spree::StockMovement
        can :manage, Spree::StockMovement, stock_item: { variant: { product: { vendor_id: @vendor_ids } } }
      end

      def apply_variant_permissions
        cannot :read, Spree::Variant
        can :manage, Spree::Variant, product: { vendor_id: @vendor_ids }
        cannot :destroy, Spree::Variant
        cannot :create, Spree::Variant
        can [:edit, :create, :destroy], Spree::Variant, product: { external_product_id: nil, vendor_id: @vendor_ids }
      end

      def apply_returns_permissions
        can :create, Spree::CustomerReturn
        can :manage, Spree::CustomerReturn, stock_location: { vendor_id: @vendor_ids }
        can :create, Spree::Refund
        can :manage, Spree::Refund, payment: { order: { vendor_id: @vendor_ids } }
        can :create, Spree::Reimbursement
        can :manage, Spree::Reimbursement, order: { vendor_id: @vendor_ids }

        can :manage, Spree::ReturnAuthorization, order: { vendor_id: @vendor_ids }

        can :read, Spree::ReimbursementType
        can :read, Spree::RefundReason
        can :read, Spree::ReturnAuthorizationReason
        can :manage, Spree::ReturnItem, inventory_unit: { order: { vendor_id: @vendor_ids } }
      end

      def apply_reports_permissions
        can :manage, Spree::Report, vendor_id: @vendor_ids
      end

      def apply_digital_permissions
        can :create, Spree::Digital
        can :manage, Spree::Digital, variant: { product: { vendor_id: @vendor_ids } }
        can :create, Spree::DigitalLink
        can :manage, Spree::DigitalLink, line_item: { order: { vendor_id: @vendor_ids } }
      end

      def apply_taxons_permissions
        can %i[index show], Spree::Taxonomy
        can %i[index show admin select_options], Spree::Taxon
        cannot :manage, Spree::Classification
      end

      def apply_export_permissions
        can :admin, Spree::Export
        can :create, Spree::Export
        can :read, Spree::Export, vendor_id: @vendor_ids
      end

      def apply_import_permissions
        can :admin, Spree::Import
        can :manage, Spree::Import, owner_type: 'Spree::Vendor', owner_id: @vendor_ids
        can :create, Spree::Import
        can :manage, Spree::ImportRow, import: { owner_type: 'Spree::Vendor', owner_id: @vendor_ids }
        can :manage, Spree::ImportMapping, import: { owner_type: 'Spree::Vendor', owner_id: @vendor_ids }
      end
    end
  end
end
