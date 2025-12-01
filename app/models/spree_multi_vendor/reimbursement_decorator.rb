module SpreeMultiVendor
  module ReimbursementDecorator
    def perform!(performer = nil, send_email: true, custom_total: nil)
      update!(total: custom_total || calculated_total, performed_by: performer)

      reimbursement_performer.perform(self)

      if unpaid_amount_within_tolerance? || custom_total.present?
        reimbursed!
        reimbursement_success_hooks.each { |h| h.call self }
        send_reimbursement_email if send_email
      else
        errored!
        reimbursement_failure_hooks.each { |h| h.call self }
        raise Spree::Reimbursement::IncompleteReimbursementError, Spree.t('validation.unpaid_amount_not_zero', amount: unpaid_amount)
      end
    end

    def custom_total?
      return false if total.nil?

      !total.between?(calculated_total - 0.01.to_d, calculated_total + 0.01.to_d)
    end
  end
end

Spree::Reimbursement.prepend(SpreeMultiVendor::ReimbursementDecorator)
