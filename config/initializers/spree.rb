Rails.application.config.after_initialize do
  Spree.admin.partials.dashboard_sidebar << 'spree/admin/dashboard/vendors'
  Spree.admin.partials.product_form_sidebar << 'spree/admin/products/form/platform_fee'

  # Filters
  Spree.admin.partials.orders_filters << 'spree/admin/orders/vendor_filter'
  Spree.admin.partials.products_filters << 'spree/admin/products/vendor_filter'

  # Order Page
  Spree.admin.partials.order_page_body << 'spree/admin/orders/marketplace_suborders'
  Spree.admin.partials.order_page_summary << 'spree/admin/orders/marketplace_summary'

  # Shipping methods
  Spree.admin.partials.shipping_methods_actions << 'spree/admin/shipping_methods/actions'

  # Metafields
  Spree.metafields.enabled_resources << Spree::Vendor

  # Translations
  Spree.translatable_resources << Spree::Vendor

  # ===============================================
  # Navigation for marketplace owners
  # ===============================================

  # Vendors
  Spree.admin.navigation.sidebar.add :vendors,
    label: :vendors,
    url: :admin_vendors_path,
    icon: 'heart-handshake',
    position: 35,
    active: -> { %w[vendors].include?(controller_name) },
    if: -> { can?(:manage, current_store) } do |vendors|
      # Vendors to review
      vendors.add :vendors_to_review,
        label: :vendors_to_review,
        url: -> { spree.admin_vendors_path(q: { state_eq: 'ready_for_review' }) },
        position: 10,
        badge: -> { ready_for_review_vendors_count },
        active: -> {  %w[vendors].include?(controller_name) && params.dig(:q, :state_eq) == 'ready_for_review' },
        if: -> { can?(:manage, current_store) && ready_for_review_vendors_count&.positive? }
    end

  # Marketplace settings
  Spree.admin.navigation.settings.add :marketplace,
    label: :marketplace,
    url: :edit_admin_marketplace_settings_path,
    icon: 'heart-handshake',
    position: 51,
    active: -> { %w[marketplace_settings].include?(controller_name) },
    if: -> { can?(:manage, current_store) }

  # ===============================================
  # Navigation for vendors
  # ===============================================
  vendor_nav = Spree.admin.navigation.register_context(:vendor_sidebar)

  # Dashboard / Getting Started
  vendor_nav.add :getting_started,
    label: 'admin.getting_started',
    url: :admin_getting_started_path,
    icon: 'map',
    position: 5,
    active: -> { controller_name == 'dashboard' && action_name == 'getting_started' },
    if: -> { !current_vendor.onboarding_completed? },
    badge: -> { "#{current_vendor.onboarding_tasks_done}/#{current_vendor.onboarding_tasks_total}" },
    badge_class: 'badge-info'

  # Dashboard / Home
  vendor_nav.add :home,
    label: :home,
    url: :admin_path,
    icon: 'home',
    position: 10,
    active: -> { controller_name == 'dashboard' && action_name == 'show' }

  # Orders with submenu
  vendor_nav.add :orders,
    label: :orders,
    url: :admin_orders_path,
    icon: 'inbox',
    position: 20,
    if: -> { can?(:manage, Spree::Order) },
    badge: -> { ready_to_ship_orders_count if ready_to_ship_orders_count&.positive? } do |orders|
      # Orders to Fulfill submenu
      orders.add :orders_to_fulfill,
        label: 'admin.orders.orders_to_fulfill',
        url: -> { spree.admin_orders_path(q: {shipment_state_not_in: [:shipped, :canceled]}) },
        position: 10,
        active: -> { controller_name == 'orders' && params.dig(:q, :shipment_state_not_in).present? },
        if: -> { ready_to_ship_orders_count&.positive? },
        badge: -> { ready_to_ship_orders_count if ready_to_ship_orders_count&.positive? }
  end

  # Products with submenu
  vendor_nav.add :products,
    label: :products,
    url: :admin_products_path,
    icon: 'package',
    position: 30,
    if: -> { can?(:manage, Spree::Product) } do |products|
      # Stock
      products.add :stock,
        label: :stock,
        url: :admin_stock_items_path,
        position: 10,
        active: -> { %w[stock_items stock_transfers].include?(controller_name) },
        if: -> { can?(:manage, Spree::StockItem) || can?(:manage, Spree::StockTransfer) }
  end

  # Section divider before settings
  vendor_nav.add :settings_section,
    section_label: 'Settings',
    position: 90

  # Vendor settings (bottom of sidebar)
  vendor_nav.add :settings,
    label: :settings,
    url: :edit_admin_vendor_settings_path,
    icon: 'settings',
    position: 100,
    if: -> { can?(:manage, current_vendor) }

  # Admin Users (bottom of sidebar)
  vendor_nav.add :admin_users,
    label: :users,
    url: :admin_admin_users_path,
    icon: 'users',
    position: 110,
    if: -> { can?(:manage, current_vendor) }

  # ===============================================
  # Vendor settings navigation
  # ===============================================
  vendor_settings_nav = Spree.admin.navigation.register_context(:vendor_settings)

  # Vendor settings (bottom of sidebar)
  vendor_settings_nav.add :settings,
    label: :settings,
    url: :edit_admin_vendor_settings_path,
    icon: 'settings',
    position: 10,
    if: -> { can?(:manage, current_vendor) },
    active: -> { %w[vendor_settings].include?(controller_name) }

  # Admin Users
  vendor_settings_nav.add :admin_users,
    label: :users,
    url: :admin_admin_users_path,
    icon: 'users',
    position: 20,
    if: -> { can?(:manage, current_vendor) },
    active: -> { %w[admin_users invitations].include?(controller_name) }

  # Shipping methods
  vendor_settings_nav.add :shipping_methods,
    label: :shipping,
    url: :admin_shipping_methods_path,
    icon: 'truck',
    position: 30,
    if: -> {  can?(:manage, Spree::ShippingMethod) },
    active: -> { %w[shipping_methods].include?(controller_name) }

  # Stock locations
  vendor_settings_nav.add :stock_locations,
    label: :stock_locations,
    url: :admin_stock_locations_path,
    icon: 'map-pin',
    position: 40,
    if: -> { can?(:manage, Spree::StockLocation) },
    active: -> { %w[stock_locations].include?(controller_name) }

  # Policies
  vendor_settings_nav.add :policies,
    label: :policies,
    url: :admin_policies_path,
    icon: 'list-check',
    position: 50,
    if: -> { can?(:manage, Spree::Policy) },
    active: -> { %w[policies].include?(controller_name) }
end

module Spree
  module PermittedAttributes
    @@product_attributes += %i[platform_fee]
    @@store_attributes += %i[
      preferred_platform_fee
      preferred_vendor_payouts_schedule_interval
    ]
  end
end
