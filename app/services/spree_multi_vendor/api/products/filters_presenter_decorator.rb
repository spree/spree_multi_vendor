module SpreeMultiVendor
  module Api
    module Products
      module FiltersPresenterDecorator
        def to_h
          option_values = Spree::OptionValues::FindAvailable.new(products_scope: products_for_filters).execute
          option_values_presenters = Spree::Filters::OptionsPresenter.new(option_values_scope: option_values).to_a
          {
            option_types: option_values_presenters.map(&:to_h),
          }
        end

        private

        def find_products_for_filters(current_store, current_currency, params)
          products = super(current_store, current_currency, params)
          products.where(vendor: [nil, Spree::Vendor.approved])
        end
      end
    end
  end
end

Spree::Api::Products::FiltersPresenter.prepend(SpreeMultiVendor::Api::Products::FiltersPresenterDecorator)
