module Spree
  module ReimbursementType::ReimbursementHelpersDecorator
    private

    def create_refund(reimbursement, payment, amount, simulate)
      refund = reimbursement.refunds.build(
        payment: payment,
        amount: amount,
        reason: Spree::RefundReason.return_processing_reason,
        refunder: reimbursement.performed_by
      )

      simulate ? refund.readonly! : refund.save!
      refund
    end
  end
end

Spree::ReimbursementType::ReimbursementHelpers.prepend(Spree::ReimbursementType::ReimbursementHelpersDecorator)
