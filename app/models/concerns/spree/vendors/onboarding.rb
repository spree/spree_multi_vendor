module Spree
  module Vendors
    module Onboarding
      extend ActiveSupport::Concern

      included do
        after_update :update_onboarding_status
        after_touch :update_onboarding_status
      end

      def onboarding_tasks_list
        [].tap do |task|
          task << :connect_shop if defined?(Spree::ExternalStore)
          task << :add_billing_address
          task << :connect_stripe if defined?(SpreeStripe::Account) && store.respond_to?(:stripe_gateway) && store.stripe_gateway.present?
          task << :add_returns_address
          task << :set_shipping_rates
          task << :add_policies
        end
      end

      def onboarding_task_done?(task)
        case task
        when :connect_shop
          respond_to?(:external_store) && external_store&.active? || prefers_not_using_external_store?
        when :connect_stripe
          respond_to?(:stripe_account) && stripe_account&.active?
        when :set_shipping_rates
          preferred_shipping_rates_confirmed
        when :add_policies
          policies.all?(&:with_body?)
        when :add_returns_address
          returns_address.present? && returns_address.persisted?
        when :add_billing_address
          billing_address.present? && billing_address.persisted?
        end
      end

      def onboarding_task_pending?(task)
        case task
        when :connect_stripe
          respond_to?(:stripe_account) && stripe_account.present? && stripe_account.pending?
        end
      end

      def onboarding_tasks_total
        @onboarding_tasks_total = onboarding_tasks_list.count
      end

      def onboarding_tasks_done
        @onboarding_tasks_done = onboarding_tasks_list.select { |task| onboarding_task_done?(task) }.count
      end

      def onboarding_completed?
        onboarding_tasks_done == onboarding_tasks_total
      end
      alias setup_completed? onboarding_completed?

      def update_onboarding_status
        complete_onboarding if onboarding_completed? && %[invited onboarding].include?(state) && !deleted?
      end

      def onboarding_percentage
        (onboarding_tasks_done / onboarding_tasks_total.to_f * 100).to_i
      end
    end
  end
end
