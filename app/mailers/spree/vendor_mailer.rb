module Spree
  class VendorMailer < Spree::BaseMailer
    helper ActionView::Helpers::SanitizeHelper
    include ApplicationHelper

    def vendor_suspended(vendor)
      @vendor = vendor
      subject = "#{current_store.name} #{Spree.t('vendor_mailer.suspended_email.subject', store_name: current_store.name, vendor_name: vendor.name)}"
      mail(to: vendor_owners_emails, subject: subject, from: from_address, reply_to: reply_to_address, store_url: current_store.url)
    end

    def vendor_approved
      @vendor = params[:vendor]
      subject = "#{Spree.t('vendor_mailer.approved_email_to_marketplace_owners.message', store_name: current_store.name, vendor_name: @vendor.name).to_s}"
      mail(to: params[:recipient].email, subject: subject, from: from_address, reply_to: reply_to_address, store_url: current_store.url)
    end

    def vendor_rejected(vendor)
      @vendor = vendor
      subject = "#{current_store.name} #{Spree.t('vendor_mailer.rejected_email.subject', store_name: current_store.name, vendor_name: vendor.name)}"
      mail(to: vendor_owners_emails, subject: subject, from: from_address, reply_to: reply_to_address, store_url: current_store.url)
    end

    def vendor_onboarding_started
      @vendor = params[:vendor]
      subject = Spree.t('vendor_mailer.onboarding_started.subject', vendor_name: @vendor.name)
      mail(to: params[:recipient].email, subject: subject, from: from_address, reply_to: reply_to_address, store_url: current_store.url)
    end

    def vendor_onboarding_completed
      @vendor = params[:vendor]
      subject = Spree.t('vendor_mailer.onboarding_completed.subject', vendor_name: @vendor.name)
      mail(to: params[:recipient].email, subject: subject, from: from_address, reply_to: reply_to_address, store_url: current_store.url)
    end

    private

    def current_store
      @current_store ||= @vendor.store
    end

    def vendor_owners_emails
      (@vendor.users.pluck(:email) << @vendor.contact_person_email).compact.uniq(&:downcase)
    end

    def marketplace_owners_emails
      @marketplace_owners_emails ||= current_store.users.pluck(:email)
    end
  end
end
