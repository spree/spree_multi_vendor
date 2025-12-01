module SpreeMultiVendor
  module PaymentMethod
    module StoreCreditDecorator
      def cancel(auth_code, payment = nil)
        store_credit_event = ::Spree::StoreCreditEvent.find_by(authorization_code: auth_code, action: ::Spree::StoreCredit::CAPTURE_ACTION)
        store_credit = store_credit_event.try(:store_credit)

        if !store_credit_event || !store_credit
          handle_action(nil, :cancel, false)
        else
          # for suborders we don't want to refund the full store credit amount, but only the amount
          # proportional to the payment for that suborder
          action = lambda do |sc|
            sc.credit(payment&.amount || store_credit_event.amount, auth_code, store_credit.currency)
          end
          handle_action(action, :cancel, auth_code)
        end
      end
    end
  end
end

Spree::PaymentMethod::StoreCredit.prepend(SpreeMultiVendor::PaymentMethod::StoreCreditDecorator)
