module SpreeMultiVendor
  module Admin
    module CheckoutsControllerDecorator
      def self.prepended(base)
        base.before_action :load_vendor, only: [:index]
      end
    end
  end
end

Spree::Admin::CheckoutsController.prepend(SpreeMultiVendor::Admin::CheckoutsControllerDecorator)
