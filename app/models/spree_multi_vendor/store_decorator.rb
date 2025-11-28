module SpreeMultiVendor
  module StoreDecorator
    def self.prepended(base)
      base.preference :platform_fee, :decimal, default: 30
      base.preference :vendor_payouts_schedule_interval, :string, default: 'monthly'
      base.preference :test_mode, :boolean, default: false
      base.has_rich_text :vendor_terms_of_service
      base.has_one_attached :shopify_app_image
    end

    def test_mode?
      preferred_test_mode
    end
  end
end

Spree::Store.prepend(SpreeMultiVendor::StoreDecorator)
