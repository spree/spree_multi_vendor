if FactoryBot.factories.registered?(:refund)
  FactoryBot.modify do
    factory :refund, class: Spree::Refund do
      association(:refunder, factory: :admin_user)
    end
  end
end
