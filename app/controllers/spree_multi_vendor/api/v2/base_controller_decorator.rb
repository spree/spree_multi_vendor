module SpreeMultiVendor
  module Api
    module V2
      module BaseControllerDecorator
        # for compatibility reasons
        def try_spree_current_user
          spree_current_user
        end

        def current_vendor
          return @current_vendor if @current_vendor.present?
          return if try_spree_current_user.nil?
          return unless try_spree_current_user.respond_to?(:vendors)
          return unless try_spree_current_user.respond_to?(:has_spree_role?)

          if try_spree_current_user.vendors.any? && try_spree_current_user.has_spree_role?(:admin)
            @current_vendor ||= try_spree_current_user.vendors.first
          end
        end
      end
    end
  end
end

Spree::Api::V2::BaseController.prepend(SpreeMultiVendor::Api::V2::BaseControllerDecorator)
