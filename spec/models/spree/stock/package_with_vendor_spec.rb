require 'spec_helper'

module Spree
  module Stock
    describe Package, type: :model do
      subject { Package.new(stock_location, contents) }

      let(:vendor) { create(:approved_vendor) }
      let(:product) { create(:product, vendor: vendor) }
      let(:variant) { product.master }
      let(:stock_location) { build(:stock_location, vendor: vendor) }
      let(:order) { create(:order) }
      let(:contents) { [] }

      def build_inventory_unit
        build(:inventory_unit, variant: variant, order: order)
      end

      # Contains regression test for #2804
      it 'builds a list of shipping methods common to all categories for stock location vendor' do
        category1 = create(:shipping_category)
        category2 = create(:shipping_category)
        method1   = create(:shipping_method, vendor: vendor)
        method2   = create(:shipping_method, vendor: vendor)
        method3   = create(:shipping_method, vendor: create(:vendor))
        method4   = create(:shipping_method)
        method5   = create(:shipping_method, vendor: vendor)
        method1.shipping_categories = [category1, category2]
        method2.shipping_categories = [category1]
        method3.shipping_categories = [category1, category2]
        method4.shipping_categories = [category1, category2]
        method5.shipping_categories = [category1, category2]
        variant1 = create(:product, shipping_category: category1, vendor: vendor).master
        variant2 = create(:product, shipping_category: category2, vendor: vendor).master
        contents = [ContentItem.new(build(:inventory_unit, variant_id: variant1.id)),
                    ContentItem.new(build(:inventory_unit, variant_id: variant1.id)),
                    ContentItem.new(build(:inventory_unit, variant_id: variant2.id))]

        package = Package.new(stock_location, contents)
        expect(package.shipping_methods.pluck(:id)).to contain_exactly(method1.id, method5.id)
      end

      context 'shipping vendor product from non-vendor stock location' do
        let(:central_stock_location) { build(:stock_location, vendor: nil) }

        it 'builds a list of shipping methods common to all categories' do
          category1 = create(:shipping_category)
          category2 = create(:shipping_category)
          method1   = create(:shipping_method)
          method2   = create(:shipping_method, vendor: vendor)
          method1.shipping_categories = [category1, category2]
          method2.shipping_categories = [category1, category2]
          variant1 = create(:product, shipping_category: category1).master
          contents = [ContentItem.new(build(:inventory_unit, variant_id: variant1.id)),
                      ContentItem.new(build(:inventory_unit, variant_id: variant1.id))]

          package = Package.new(central_stock_location, contents)
          expect(package.shipping_methods).to eq([method1])
        end
      end
    end
  end
end
