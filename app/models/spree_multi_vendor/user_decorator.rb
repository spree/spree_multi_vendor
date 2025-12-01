module SpreeMultiVendor
  module UserDecorator
    def self.prepended(base)
      base.has_many :orders, -> { without_vendor }, foreign_key: :user_id, class_name: 'Spree::Order'
      base.has_many :completed_orders, -> { complete.without_vendor }, class_name: 'Spree::Order'
    end

    def completed_orders_for_store(store)
      orders.for_store(store).complete.without_vendor.order(currency: :desc)
    end
  end
end

if Spree.user_class.present?
  Spree.user_class.prepend(SpreeMultiVendor::UserDecorator) unless Spree.user_class.include?(SpreeMultiVendor::UserDecorator)
end
