module Spree
  class MarketplaceCommission < Spree.base_class
    self.table_name = 'spree_platform_fees'

    extend DisplayMoney
    money_methods :amount, :discount, :amount_before_discount

    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :feeable, polymorphic: true

    validates :amount, presence: true
    validates :order, presence: true

    ITEM_LABEL = 'Item commission'
    REVERSE_ORDER_LABEL = 'Reverse order commission'
    REVERSE_ITEM_LABEL = 'Reverse item commission'

    scope :active, -> { where(active: true) }
    scope :positive, -> { where(label: ITEM_LABEL) }
    scope :reversed, -> { where(label: [REVERSE_ITEM_LABEL, REVERSE_ORDER_LABEL]) }

    alias amount_money display_amount
    delegate :currency, to: :order

    def discounted?
      discount.positive?
    end

    def reversed?
      label.in?([REVERSE_ITEM_LABEL, REVERSE_ORDER_LABEL])
    end

    def item_name
      label == REVERSE_ORDER_LABEL ? order.number : feeable.try(:name)
    end

    def currency
      order.try(:currency)
    end

    def discount
      metadata = feeable.try(:private_metadata) || {}
      metadata.fetch(:platform_fee_discount, 0).to_d
    end

    def amount_before_discount
      amount + discount
    end

    def rate_after_discount
      return rate if discount.zero?

      amount_before_discount = amount + discount
      (amount / amount_before_discount) * rate
    end

    def display_amount_with_sign(before_discount: false)
      amount_to_display = before_discount ? display_amount_before_discount : display_amount
      reversed? ? -amount_to_display : amount_to_display
    end
  end
end
