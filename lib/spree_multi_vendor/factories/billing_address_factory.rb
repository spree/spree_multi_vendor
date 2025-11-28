FactoryBot.define do
  factory :billing_address, class: Spree::BillingAddress, parent: :address do
    trait :skip_mainstreet_validation do
      skip_mainstreet_validation { true }
    end
  end
end
