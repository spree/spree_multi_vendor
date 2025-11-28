class Spree::ReimbursementType::OriginalPayment < Spree::ReimbursementType
  extend Spree::ReimbursementType::ReimbursementHelpers

  class << self
    def reimburse(reimbursement, _return_items, simulate)
      unpaid_amount = reimbursement.total
      payments = reimbursement.order.payments.completed

      reimbursement_list, _unpaid_amount = create_refunds(reimbursement, payments, unpaid_amount, simulate)
      reimbursement_list
    end
  end
end
