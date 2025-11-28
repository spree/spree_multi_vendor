module Spree
  module Admin
    class VendorsController < ResourceController
      before_action :authorize_vendor_admin

      add_breadcrumb Spree.t(:vendors), :admin_vendors_path
      add_breadcrumb_icon 'heart-handshake'

      def show
        @returns_address = @vendor.returns_address
        @billing_address = @vendor.billing_address
        @vendor_users = @vendor.users.includes(role_users: :role).where(role_users: { resource: @vendor })

        add_breadcrumb @vendor.name, spree.admin_vendor_path(@vendor)
      end

      def new
        @vendor = Spree::Vendor.new
        @vendor.platform_fee = current_store.preferred_platform_fee
      end

      def create
        @vendor = Spree::Vendor.new(permitted_resource_params)
        @vendor.platform_fee ||= current_store.preferred_platform_fee
        @vendor.invited_by = try_spree_current_user

        if @vendor.save
          respond_to do |format|
            format.html do
              flash[:success] = "Invitation email was sent to #{@vendor.contact_person_email}"
              redirect_to spree.admin_vendor_path(@vendor)
            end
            format.turbo_stream do
              flash.now[:success] = "Invitation email was sent to #{@vendor.contact_person_email}"
            end
          end
        else
          respond_to do |format|
            format.html { render :new }
            format.turbo_stream
          end
        end
      end

      def approve
        @vendor.approve!
        flash[:success] = "#{@vendor.name} is now approved and all of their active products are now available on the storefront for purchase"
        redirect_back fallback_location: spree.admin_vendor_path(@vendor)
      end

      def reject
        @vendor.reject!
        flash[:success] = "Vendor is now rejected. We've also sent them an email notification"
        redirect_back fallback_location: spree.admin_vendor_path(@vendor)
      end

      def suspend
        @vendor.suspend!
        flash[:success] = "Vendor is now suspended. We've also sent them an email notification"
        redirect_back fallback_location: spree.admin_vendor_path(@vendor)
      end

      def archive
        @vendor.destroy!
        flash[:success] = 'Partner is now archived'
        redirect_to spree.admin_vendors_path
      end

      def confirm_shipping_rates
        @vendor.update!(preferred_shipping_rates_confirmed: true)

        flash[:success] = "Shipping rates confirmed, you're all set!"

        redirect_to admin_shipping_methods_path
      end

      def select_options
        render json: vendors_scope.to_tom_select_json, status: :ok, last_modified: vendors_scope.maximum(:updated_at)
      end

      private

      def update_turbo_stream_enabled?
        true
      end

      def collection_includes
        [:billing_address, :returns_address, :shipping_methods, :policies, logo_attachment: :blob]
      end

      def find_resource
        vendors_scope.with_deleted.friendly.find(params[:id])
      end

      def vendors_scope
        Spree::Vendor
      end

      def location_after_save
        spree.admin_vendor_path(@vendor)
      end

      def create_turbo_stream_enabled?
        true
      end

      def authorize_vendor_admin
        authorize! :manage, Spree::Vendor

        raise CanCan::AccessDenied if current_vendor.present? && current_vendor != @vendor
      end

      def permitted_resource_params
        params.require(:vendor).permit(:name,
                                       :payouts_schedule_interval,
                                       :platform_fee,
                                       :about,
                                       :logo, :cover_photo, :square_logo,
                                       :contact_person_email,
                                       returns_address_attributes: Spree::PermittedAttributes.address_attributes,
                                       billing_address_attributes: Spree::PermittedAttributes.address_attributes)
      end
    end
  end
end
