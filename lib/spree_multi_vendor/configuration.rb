module SpreeMultiVendor
  class Configuration < Spree::Preferences::Configuration
    preference :shopify_app_name, :string, default: 'Vendo Connect'
    preference :default_policies, :array, default: ['returns_policy']
  end
end
