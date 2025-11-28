module SpreeMultiVendor
  module Admin
    module BaseControllerDecorator
      def self.prepended(base)
        base.helper 'spree/admin/vendor'
        base.include(Spree::Admin::VendorHelper)

        base.helper_method :current_vendor
        base.helper_method :vendor_state_options

        base.prepend_before_action :set_current_vendor
        base.before_action :set_vendor_id, only: [:create, :update]
      end

      def set_vendor_id
        return unless current_vendor
        return unless defined?(resource)
        return unless resource
        return unless params[resource.object_name.to_sym]
        return unless resource.respond_to?(:vendor_id)

        params[resource.object_name.to_sym][:vendor_id] = current_vendor.id
      end

      def set_current_vendor
        return if params[:vendor_id].blank?
        return unless try_spree_current_user
        return if try_spree_current_user.spree_admin?

        vendor = try_spree_current_user.vendors.with_access_to_ui.find_by(id: params[:vendor_id])
        return if vendor.blank?

        @current_vendor = vendor
        session[:current_vendor_id] = @current_vendor.id
      end

      def current_vendor
        return unless defined?(try_spree_current_user)
        return if try_spree_current_user.nil?
        return unless try_spree_current_user.respond_to?(:vendors)

        return @current_vendor if @current_vendor.present?
        return if @current_vendor_fetched

        @current_vendor_fetched = true

        return if try_spree_current_user.spree_admin?

        vendor_scope = try_spree_current_user.vendors.with_access_to_ui

        @current_vendor ||= session[:current_vendor_id].present? ? vendor_scope.find_by(id: session[:current_vendor_id]) : vendor_scope.first
      end
    end
  end
end

Spree::Admin::BaseController.prepend(SpreeMultiVendor::Admin::BaseControllerDecorator)
