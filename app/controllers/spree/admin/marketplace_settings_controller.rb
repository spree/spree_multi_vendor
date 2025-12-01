module Spree
  module Admin
    class MarketplaceSettingsController < BaseController
      include Spree::Admin::SettingsConcern

      def edit
      end

      def update
        if current_store.update(permitted_params)
          remove_assets(%w[shopify_app_image], object: current_store)
          redirect_to spree.edit_admin_marketplace_settings_path, notice: flash_message_for(current_store, :successfully_updated)
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def permitted_params
        params.require(:store).permit(:preferred_platform_fee, :preferred_vendor_payouts_schedule_interval, :preferred_test_mode, :vendor_terms_of_service, :shopify_app_image)
      end

      def model_class
        Spree::Store
      end
    end
  end
end
