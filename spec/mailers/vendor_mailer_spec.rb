require 'spec_helper'
require 'email_spec'

RSpec.describe Spree::VendorMailer, type: :mailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  let!(:store) { Spree::Store.default }
  let!(:marketplace_owner) { create(:admin_user) }
  let!(:vendor) { create(:vendor, invited_by: marketplace_owner) }
  let!(:vendor_owner) { create(:vendor_user, vendor: vendor) }

  describe '#vendor_suspended' do
    let(:vendor_suspended_mail) { described_class.vendor_suspended(vendor) }

    it 'has Vendor Owner email as to mail' do
      expect(vendor_suspended_mail.to).to include(vendor_owner.email)
    end

    it 'contains Store name and Vendor name in subject' do
      expect(vendor_suspended_mail.subject).to include(store.name)
      expect(vendor_suspended_mail.subject).to include(vendor.name)
    end

    it 'has the correct message in the body' do
      message = 'If you would like to discuss this matter please contact' + \
        " us via email #{store.mail_from_address}"

      expect(vendor_suspended_mail).to have_body_text("We're sorry but your organization was suspended.")
      expect(vendor_suspended_mail).to have_body_text(message)
    end
  end

  describe '#vendor_approved' do
    describe 'email sent to vendor owners' do
      subject(:vendor_approved_mail) { described_class.with(vendor: vendor, recipient: vendor_owner).vendor_approved }

      it 'has Vendor Owner email as to mail' do
        expect(vendor_approved_mail.to).to include(vendor_owner.email)
      end

      it 'contains Store name and Vendor name in subject' do
        expect(vendor_approved_mail.subject).to include(store.name)
        expect(vendor_approved_mail.subject).to include(vendor.name)
      end

      it 'has the correct message in the body' do
        expect(vendor_approved_mail).to have_body_text(spree.admin_dashboard_path)
      end
    end

    describe 'email sent to marketplace owners' do
      subject(:vendor_approved_mail) do
        described_class.with(
          vendor: vendor,
          recipient: marketplace_owner
        ).vendor_approved
      end

      it 'has marketplace owner email as to mail' do
        expect(vendor_approved_mail.to).to include(marketplace_owner.email)
      end

      it 'has valid subject' do
        expect(vendor_approved_mail.subject).to eq "#{vendor.name} has been approved to start selling on #{vendor.store.name}!"
      end

      it 'has the correct message in the body' do
        expect(vendor_approved_mail).to have_body_text "#{vendor.name} has been approved to start selling on #{vendor.store.name}!"
        expect(vendor_approved_mail).to have_body_text(spree.admin_vendor_url(vendor, host: vendor.store.url))
      end
    end
  end

  describe '#vendor_rejected' do
    let(:vendor_rejected_mail) { described_class.vendor_rejected(vendor) }

    it 'has Vendor Owner email as to mail' do
      expect(vendor_rejected_mail.to).to include(vendor_owner.email)
    end

    it 'contains Store name and Vendor name in subject' do
      expect(vendor_rejected_mail.subject).to include(store.name)
      expect(vendor_rejected_mail.subject).to include(vendor.name)
    end

    it 'has the correct message in the body' do
      expect(vendor_rejected_mail).to have_body_text(store.mail_from_address)
    end
  end

  describe '#vendor_onboarding_started' do
    let(:vendor_onboarding_started_mail) { described_class.with(vendor: vendor, recipient: marketplace_owner).vendor_onboarding_started }

    context 'to mail' do
      it 'has a Store Owners emails as to mail' do
        expect(vendor_onboarding_started_mail.to).to eq([marketplace_owner.email])
      end
    end

    it 'contains Vendor name and link to Vendor profile in subject' do
      expect(vendor_onboarding_started_mail.subject).to include(vendor.name)
      expect(vendor_onboarding_started_mail.subject).to include('started the onboarding process')
    end

    it 'has the correct message in the body' do
      expect(vendor_onboarding_started_mail).to have_body_text(vendor.name)
      expect(vendor_onboarding_started_mail).to have_body_text(spree.admin_vendor_url(vendor, host: vendor.store.url))
    end
  end

  describe '#vendor_onboarding_completed' do
    let(:vendor_onboarding_completed_mail) { described_class.with(vendor: vendor, recipient: marketplace_owner).vendor_onboarding_completed }

    context 'to mail' do
      it 'has a Store Owners emails as to mail' do
        expect(vendor_onboarding_completed_mail.to).to eq([marketplace_owner.email])
      end
    end

    it 'contains Vendor name and link to Vendor profile in subject' do
      expect(vendor_onboarding_completed_mail).to have_subject(/#{vendor.name}/)
      expect(vendor_onboarding_completed_mail).to have_subject(/completed their onboarding/)
    end

    it 'has the correct message in the body' do
      expect(vendor_onboarding_completed_mail).to have_body_text(vendor.name)
      expect(vendor_onboarding_completed_mail).to have_body_text(spree.admin_vendor_url(vendor, host: vendor.store.url))
    end
  end
end
