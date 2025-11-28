FactoryBot.define do
  factory :vendor_user, class: Spree.admin_user_class, parent: :admin_user do
    without_admin_role

    transient do
      vendor { nil }
    end

    after(:create) do |user, evaluator|
      evaluator.vendor.add_user(user) if evaluator.vendor.present?
    end
  end
end
