module Spree
  module Admin
    module VendorHelper
      def invite_vendor_button(options = {})
        return unless can?(:create, Spree::Vendor)

        options[:class] ||= 'btn btn-primary'

        content_tag(:div, data: { toggle: 'modal', target: '#modal' }) do
          link_to_with_icon(
            'send',
            Spree.t(:invite_vendor),
            spree.new_admin_vendor_path,
            class: options[:class],
            data: { turbo_frame: 'dialog_modal' }
          )
        end
      end

      def vendor_state_options
        @vendor_state_options ||= Spree::Vendor.state_machines[:state].states.collect { |s| [Spree.t("vendor_states.#{s.name}"), s.value] }
      end

      def vendor_logo_link(vendor = nil, options = {})
        vendor ||= current_vendor

        options[:height] ||= 30
        options[:class] ||= 'd-flex align-items-center font-weight-bold justify-content-start btn'
        options[:data] ||= {}
        options[:data]['turbo-frame'] ||= '_top'

        if vendor.deleted?
          content_tag :span, vendor.display_name, class: options[:class], style: 'text-decoration: line-through;'
        else
          link_to spree.admin_vendor_path(vendor), class: options[:class], data: options[:data] do
            [
              (vendor_logo(vendor, options) || first_letter_icon(vendor.name, options)),
              content_tag(:span, class: 'ml-2') { vendor.display_name }
            ].compact.join.html_safe
          end
        end
      end

      def vendor_name_link(vendor = nil, options = {})
        vendor ||= current_vendor

        options[:class] ||= 'text-dark'

        if vendor.deleted?
          content_tag :span, vendor.display_name, class: options[:class], style: 'text-decoration: line-through;'
        else
          link_to spree.admin_vendor_path(vendor), class: options[:class], data: { 'turbo-frame': '_top' } do
            vendor.display_name
          end
        end
      end

      def vendor_logo(vendor, options = {})
        if vendor.logo.attached? && vendor.logo.variable?
          spree_image_tag(
            vendor.logo,
            width: options[:height],
            height: options[:height],
            alt: vendor.name,
            loading: :lazy,
            class: 'with-tip rounded-sm',
            title: vendor.name
          )
        end
      end

      def vendors_scope
        @vendors_scope ||= Spree::Vendor.accessible_by(current_ability).order(:name)
      end

      def vendors_list
        @vendors_list ||= vendors_scope.pluck(:name, :id)
      end

      def vendor_options
        if params.dig(:q, :vendor_orders_vendor_id_eq)
          vendors_scope.where(id: params.dig(:q, :vendor_orders_vendor_id_eq)).pluck(:name, :id)
        else
          []
        end
      end

      def vendor_filter_dropdown_value
        case params.dig(:q, :state_eq)
        when 'approved'
          Spree.t('admin.vendors.approved')
        when 'rejected'
          Spree.t('admin.vendors.rejected')
        when 'suspended'
          Spree.t('admin.vendors.suspended')
        when 'ready_for_review'
          Spree.t('admin.vendors.ready_for_review')
        when 'onboarding'
          Spree.t('admin.vendors.onboarding')
        when 'invited'
          Spree.t('admin.vendors.invited')
        when 'pending'
          Spree.t('admin.vendors.pending')
        else
          Spree.t('admin.vendors.all')
        end
      end

      def vendor_status_badge(vendor = nil, options = {})
        vendor ||= current_vendor

        return if vendor.nil?

        case vendor.state.to_s
        when 'approved'
          title = if current_vendor.present?
                    "Your store is live on #{current_store.name}"
                  else
                    'Partner is live!'
                  end
          icon = 'check.svg'
          badge = 'success'
        when 'ready_for_review'
          title = if current_vendor.present?
                    "#{current_store.name} team will review your shop shortly"
                  else
                    'Partner completed onboarding tasks, ready for review'
                  end
          icon = 'eye'
          badge = 'ready_for_review'
        when 'suspended'
          title = if current_vendor.present?
                    "Your store is suspended. Please contact #{current_store.name} for more information."
                  else
                    'Partner is suspended'
                  end
          icon = 'exclamation-circle'
          badge = 'warning'
        when 'rejected'
          title = if current_vendor.present?
                    "Your store was rejected. Please contact #{current_store.name} for more information."
                  else
                    'Partner was rejected'
                  end

          icon = 'exclamation-circle'
          badge = 'warning'
        when 'invited' || 'pending'
          title = 'Partner invited'
          icon = 'send.svg'
        else
          title = if current_vendor.present?
                    "Complete your tasks to start selling on #{current_store.name}"
                  else
                    'Partner needs to complete their onboarding tasks'
                  end
        end

        icon ||= 'progress'
        badge ||= 'light border'

        return if title.blank? || icon.blank?

        content_tag :span, class: "vendor-status-badge badge  badge-#{badge} #{options[:class]} with-tip px-2", title: title do
          icon(icon) + vendor.state.humanize.capitalize
        end
      end

      def ready_for_review_vendors_count
        if defined?(current_store) && current_store && !current_vendor.present?
          @ready_for_review_vendors_count ||= Spree::Vendor.ready_for_review.count
        end
      end
    end
  end
end
