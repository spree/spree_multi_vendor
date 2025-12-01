module Spree
  class Order < Spree.base_class
    module Emails
      def deliver_order_confirmation_email
        return if line_items.where.not(vendor_id: nil).any?

        unless completed?
          errors.add(:base, Spree.t(:order_email_resent_error))
          return
        end

        OrderMailer.confirm_email(id).deliver_later if send_consumer_transactional_emails?

        update_column(:confirmation_delivered, true) unless confirmation_delivered
      end

      def deliver_splitted_order_confirmation_email
        return unless send_consumer_transactional_emails?

        Spree::OrderMailer.splitted_order_confirm_email(id).deliver_later
        update_column(:confirmation_delivered, true)
      end

      def deliver_store_owner_order_notification_email?
        !store.test_mode? && store.new_order_notifications_email.present? && !store_owner_notification_delivered? && send_consumer_transactional_emails?
      end

      def deliver_store_owner_order_notification_email
        OrderMailer.store_owner_notification_email(id).deliver_later
        update_column(:store_owner_notification_delivered, true)
      end

      def send_cancel_email
        OrderMailer.cancel_email(id).deliver_later if send_consumer_transactional_emails?

      end

      private

      def send_consumer_transactional_emails?
        store.prefers_send_consumer_transactional_emails?
      end
    end
  end
end
