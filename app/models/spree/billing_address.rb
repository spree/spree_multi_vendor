module Spree
  class BillingAddress < Address
    def require_name?
      false
    end

    def show_company_address_field?
      true
    end
  end
end
