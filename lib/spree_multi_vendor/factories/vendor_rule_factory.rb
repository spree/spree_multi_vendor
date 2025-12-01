FactoryBot.define do
  factory :vendor_taxon_rule, class: SpreeMultiVendor::TaxonRules::Vendor do
    trait :is_equal_to do
      match_policy { :is_equal_to }
    end

    trait :is_not_equal_to do
      match_policy { :is_not_equal_to }
    end

    trait :contains do
      match_policy { :contains }
    end

    trait :does_not_contain do
      match_policy { :does_not_contain }
    end
  end
end
