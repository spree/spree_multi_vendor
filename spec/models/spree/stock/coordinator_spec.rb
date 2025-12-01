require 'spec_helper'

RSpec.describe Spree::Stock::Coordinator, type: :model do
  let(:coordinator) { described_class.new(order) }

  describe '#build_packages' do
    subject(:packages) { coordinator.build_packages }

    shared_examples_for 'building one package' do
      let(:stock_location) { Spree::StockLocation.last }

      let(:order_products) { order.products }
      let(:order_stock_locations) { order_products.flat_map(&:stock_items).map(&:stock_location).uniq }

      let(:package_stock_location) { packages.first.stock_location }
      let(:package_products) { packages.first.contents.map(&:variant).map(&:product) }

      it 'builds one package for the same stock location' do
        expect(order_stock_locations).to contain_exactly(stock_location)
        expect(packages.count).to eq(1)
        expect(package_stock_location.vendor).to eq(vendor)
        expect(package_products).to contain_exactly(*order_products)
      end
    end

    context 'for a single vendor' do
      let(:order) { create(:vendor_order_with_line_items, line_items_count: 2, vendor: vendor) }
      let(:vendor) { create(:vendor) }

      include_examples 'building one package'
    end

    context 'for multiple vendors' do
      let(:order) { create(:order, line_items: vendor_line_items) }
      let(:vendor_line_items) { create_list(:vendor_line_item, 2) }

      let(:vendor_1_line_item) { vendor_line_items[0] }
      let(:vendor_1) { vendor_line_items[0].vendor }

      let(:vendor_2_line_item) { vendor_line_items[1] }
      let(:vendor_2) { vendor_line_items[1].vendor }

      let(:order_stock_locations) { order.products.flat_map(&:stock_items).map(&:stock_location).uniq }
      let(:package_stock_locations) { packages.map(&:stock_location) }

      it 'builds one package for the same stock location per vendor' do
        expect(package_stock_locations).to contain_exactly(*order_stock_locations)

        vendor_1_package = packages.find { |package| package.stock_location.vendor == vendor_1 }
        vendor_1_package_products = vendor_1_package.contents.map(&:variant).map(&:product)
        expect(vendor_1_package_products).to contain_exactly(vendor_1_line_item.product)

        vendor_2_package = packages.find { |package| package.stock_location.vendor == vendor_2 }
        vendor_2_package_products = vendor_2_package.contents.map(&:variant).map(&:product)
        expect(vendor_2_package_products).to contain_exactly(vendor_2_line_item.product)
      end
    end

    context 'without vendors' do
      let!(:order) { create(:order_with_line_items, line_items_count: 2) }
      let(:vendor) { nil }

      include_examples 'building one package'
    end
  end
end
