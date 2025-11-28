module SpreeMultiVendor
  module Admin
    module ProductsControllerDecorator
      def self.prepended(base)
        base.before_action :load_vendor, only: :index
        base.before_action :strip_platform_fee_param, only: :update

        base.new_action.before :set_product_vendor
      end

      def assign_extra_collection_params
        load_vendor
        params[:q][:vendor_id_eq] = @vendor.id if @vendor.present? && params[:q].present?
      end

      private

      def load_vendor
        @vendor = Spree::Vendor.friendly.find(params[:vendor_id]) if params[:vendor_id].present? && !current_vendor.present?
      end

      def set_product_vendor
        # Needed for ability checks
        @product.vendor = current_vendor
      end

      def strip_platform_fee_param
        return if can? :manage_commission, @product

        params[:product].delete(:platform_fee)
      end

      def master_stock_items_locations_opts
        { vendor: @product.vendor || current_vendor }
      end
    end
  end
end

Spree::Admin::ProductsController.prepend(SpreeMultiVendor::Admin::ProductsControllerDecorator)
