module SpreeMultiVendor
  module InvitationDecorator
    def after_accept
      super
      resource.start_onboarding! if resource.is_a?(Spree::Vendor) && (resource.invited? || resource.pending?)
    end
  end
end

Spree::Invitation.prepend(SpreeMultiVendor::InvitationDecorator)
