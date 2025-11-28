require 'spec_helper'

RSpec.describe Spree::Invitation, type: :model do
  let!(:store) { create(:store, default: true) }
  let(:invitation) { create(:invitation) }

  before do
    clear_enqueued_jobs
  end

  describe 'State Machine' do
    it 'has initial state of pending' do
      expect(invitation.status).to eq('pending')
    end

    context 'when accepting an invitation' do
      before do
        invitation.invitee = create(:admin_user, :without_admin_role)
      end

      context 'when the resource is a vendor' do
        it 'starts onboarding' do
          invitation.resource = create(:invited_vendor)
          invitation.accept!
          expect(invitation.resource.reload.onboarding?).to be true
        end
      end
    end
  end
end
