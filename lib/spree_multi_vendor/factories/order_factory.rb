if FactoryBot.factories.registered?(:order)
  FactoryBot.modify do
    factory :order, class: Spree::Order do
      trait :with_external_id do
        external_id { SecureRandom.uuid }
      end
    end
  end
end
