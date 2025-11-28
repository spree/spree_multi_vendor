FactoryBot.define do
  factory :canada_country, class: Spree::Country do
    iso  { 'CA' }
    iso3 { 'CAN' }
    name { 'Canada' }
    iso_name { 'CANADA' }
    zipcode_required  { true }
  end

  factory :usa_country, class: Spree::Country do
    iso  { 'US' }
    iso3 { 'USA' }
    name { 'United States' }
    iso_name { 'UNITED STATES' }
    states_required { true }
    zipcode_required { true }
  end

  factory :poland_country, class: Spree::Country do
    iso  { 'PL' }
    iso3 { 'POL' }
    name { 'Poland' }
    iso_name { 'POLAND' }
    zipcode_required { true }
  end

  factory :uk_country, class: Spree::Country do
    iso  { 'GB' }
    iso3 { 'GBR' }
    name { 'United Kingdom' }
    iso_name { 'UNITED KINGDOM' }
    zipcode_required { true }
  end

  factory :ireland_country, class: Spree::Country do
    iso  { 'IE' }
    iso3 { 'IRL' }
    name { 'Ireland' }
    iso_name { 'UNITED KINGDOM' }
    zipcode_required { false }
    states_required { true }
  end
end
