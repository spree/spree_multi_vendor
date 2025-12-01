module Spree
  module Admin
    class VendorSettingsController < BaseController
      include Spree::Admin::SettingsConcern

      before_action :require_vendor

      def edit
      end

      def update
        if current_vendor.update(permitted_params)
          redirect_to spree.edit_admin_vendor_settings_path, notice: flash_message_for(current_vendor, :successfully_updated)
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def permitted_params
        params.require(:vendor).permit(:name, :billing_email,
                                        billing_address_attributes: permitted_address_attributes,
                                        returns_address_attributes: permitted_address_attributes)
      end

      def model_class
        Spree::Vendor
      end

      def require_vendor
        redirect_to spree.admin_dashboard_path if current_vendor.nil?
      end
    end
  end
end
