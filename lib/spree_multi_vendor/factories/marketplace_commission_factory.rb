FactoryBot.define do
  factory :marketplace_commission, class: Spree::MarketplaceCommission do
    amount { 10.0 }
    active { true }
    label { Spree::MarketplaceCommission::ITEM_LABEL }
    order { build(:order) }
    feeable { build(:line_item) }
  end
end
