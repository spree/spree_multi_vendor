module SpreeMultiVendor
  module PromotionDecorator
    def self.prepended(base)
      base.const_set(:UNACTIVATABLE_ORDER_STATES, ['complete', 'awaiting_return', 'returned', 'splitted'])
    end
  end
end

Spree::Promotion.prepend(SpreeMultiVendor::PromotionDecorator)
