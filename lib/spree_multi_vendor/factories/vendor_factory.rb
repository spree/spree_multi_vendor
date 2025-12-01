FactoryBot.define do
  factory :vendor, class: Spree::Vendor do
    name { FFaker::Company.name }
    contact_person_email { FFaker::Internet.email }
    invited_by_email { false }
    state { :approved }

    factory :approved_vendor do
      state { :approved }
    end

    factory :onboarding_vendor do
      state { :onboarding }
    end

    factory :rejected_vendor do
      state { :rejected }
    end

    factory :invited_vendor do
      invited_by_email { true }
      state { :invited }
    end

    trait :with_logo do
      before(:create) do |vendor|
        file = File.new(Spree::Core::Engine.root + 'spec/fixtures' + 'thinking-cat.jpg')
        vendor.logo.attach(io: file, filename: 'logo', content_type: 'image/jpeg')
      end
    end

    trait :with_cover_photo do
      before(:create) do |vendor|
        file = File.new(Spree::Core::Engine.root + 'spec/fixtures' + 'thinking-cat.jpg')
        vendor.cover_photo.attach(io: file, filename: 'logo', content_type: 'image/jpeg')
      end
    end
  end
end
