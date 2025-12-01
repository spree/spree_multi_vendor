FactoryBot.define do
  factory :returns_address, class: Spree::ReturnsAddress, parent: :address do
    trait :skip_mainstreet_validation do
      skip_mainstreet_validation { true }
    end
  end
end
