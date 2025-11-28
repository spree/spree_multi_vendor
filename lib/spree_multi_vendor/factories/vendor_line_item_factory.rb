FactoryBot.define do
  factory :vendor_line_item, class: Spree::LineItem, parent: :line_item do
    product do
      price_currency = order&.currency || Spree::Store.default.default_currency
      product_vendor = vendor || order.vendor || create(:approved_vendor)

      product = if order&.store&.present?
        create(:vendor_product_in_stock, stores: [order.store], vendor: product_vendor, price_currency: price_currency)
      else
        create(:vendor_product_in_stock, vendor: product_vendor, price_currency: price_currency)
      end

      product
    end
  end
end
