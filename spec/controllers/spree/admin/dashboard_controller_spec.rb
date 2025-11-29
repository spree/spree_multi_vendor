require 'spec_helper'

describe Spree::Admin::DashboardController, type: :controller do
  stub_authorization!
  render_views

  let(:store) { Spree::Store.default }

  describe '#show' do
    it 'renders welcome page' do
      get :show
      expect(response).to have_http_status(200)
    end
  end

  describe '#analytics' do
    context 'view' do
      it 'renders analytics' do
        get :analytics
        expect(response).to have_http_status(200)
      end
    end

    context 'with vendor' do
      context 'missing vendor' do
        let!(:vendor) { create(:approved_vendor) }
        let!(:admin_user) { create(:vendor_user, vendor: vendor) }

        before do
          get :analytics, params: { vendor_id: 'missing' }
        end

        it 'fallbacks to default vendor for this user' do
          expect(controller.current_vendor).to eq(vendor)
        end
      end

      context 'vendor from different account' do
        let!(:vendor) { create(:approved_vendor) }
        let!(:other_vendor) { create(:approved_vendor) }
        let!(:admin_user) { create(:vendor_user, vendor: vendor) }

        before { get(:analytics, params: { vendor_id: other_vendor.id }) }

        it 'fallbacks to default vendor for this user' do
          expect(controller.current_vendor).to eq(vendor)
        end
      end
    end

    xcontext 'products_scope' do
      let!(:product1) { create(:product_in_stock) }
      let!(:product2) { create(:product_in_stock) }
      let!(:other_product) { create(:product, stores: [create(:store)]) }

      subject do
        @controller.instance_variable_get(:@products_scope)
      end

      context 'without vendor' do
        it 'is set to all products in the store' do
          get :analytics
          expect(subject).to contain_exactly(product1, product2)
        end
      end

      xcontext 'with vendors' do
        let!(:vendor) { create(:approved_vendor) }
        let!(:other_vendor) { create(:approved_vendor) }
        let!(:admin_user) { create(:vendor_user, vendor: vendor) }

        before do
          product1.update_column(:vendor_id, vendor.id)
          product2.update_column(:vendor_id, other_vendor.id)
        end

        it 'is set to products from the current store and vendor' do
          get :analytics, params: { vendor_id: vendor.id }
          expect(subject).to contain_exactly(product1)
        end
      end
    end

    xcontext 'orders_scope' do
      let!(:order1) { create(:completed_order_with_totals) }
      let!(:order2) { create(:completed_order_with_totals) }
      let!(:incomplete_order) { create(:order) }
      let!(:other_store) { create(:store) }
      let!(:order_in_other_store) { create(:completed_order_with_totals, store: other_store) }

      subject do
        @controller.instance_variable_get(:@orders_scope)
      end

      context 'currency' do
        let!(:order_in_other_currency) { create(:completed_order_with_totals, currency: 'EUR') }

        context 'with default currency' do
          it 'is set to all orders with the default currency' do
            get :analytics
            expect(subject.unscope(:group)).to contain_exactly(order1, order2)
          end
        end

        context 'with currency=EUR' do
          it 'is set to all orders with the given currency' do
            get :analytics, params: { analytics_currency: 'EUR' }
            expect(subject.unscope(:group)).to contain_exactly(order_in_other_currency)
          end
        end
      end

      xcontext 'with vendors' do
        let!(:vendor) { create(:approved_vendor) }
        let!(:other_vendor) { create(:approved_vendor) }
        let!(:admin_user) { create(:vendor_user, vendor: vendor) }
        let!(:order1) { create(:vendor_completed_order_with_totals, vendor: vendor) }
        let!(:order2) { create(:vendor_completed_order_with_totals, vendor: vendor) }

        it 'is set to orders from the current store and vendor' do
          get :analytics, params: { vendor_id: vendor.id }
          expect(subject.unscope(:group)).to contain_exactly(order1)
        end
      end

      context 'grouping by time range' do
        let!(:order_from_this_week) { create(:completed_order_with_totals) }
        let!(:order_from_this_month) { create(:completed_order_with_totals) }

        before do
          order_from_this_week.update_column(:completed_at, 5.days.ago)
          order_from_this_month.update_column(:completed_at, 25.days.ago)
        end

        context 'default time range (last 24 hours)' do
          it 'is set to the orders from the current store completed in the last 24 hours' do
            get :analytics

            num_orders_by_hour = subject.count.values
            expect(num_orders_by_hour.sum).to eq(2)
          end
        end
      end
    end

    xcontext 'product_units_sold' do
      let!(:incomplete_order) { create(:order) }
      let!(:order_in_other_store) { create(:completed_order_with_totals, store: create(:store)) }
      let!(:order1) { create(:completed_order_with_totals) }
      let!(:order2) { create(:completed_order_with_totals) }
      let(:product1) { order1.line_items.first.product }
      let(:product2) { order2.line_items.first.product }

      subject do
        @controller.instance_variable_get(:@product_units_sold)
      end

      context 'currency' do
        let!(:order_in_other_currency) { create(:completed_order_with_totals, currency: 'EUR') }

        context 'with default currency' do
          it 'is set to all orders with the default currency' do
            get :analytics
            expect(subject.to_a).to contain_exactly([product1.name, 1], [product2.name, 1])
          end
        end

        context 'with currency=EUR' do
          it 'is set to all orders with the given currency' do
            get :analytics, params: { analytics_currency: 'EUR' }
            expect(subject.to_a).to contain_exactly([order_in_other_currency.line_items.take.product.name, 1])
          end
        end
      end

      xcontext 'with vendors' do
        let!(:vendor) { create(:approved_vendor) }
        let!(:other_vendor) { create(:approved_vendor) }
        let!(:admin_user) { create(:vendor_user, vendor: vendor) }

        before do
          order1.update_column(:vendor_id, vendor.id)
          order2.update_column(:vendor_id, other_vendor.id)
        end

        it 'is counts units sold for orders the current store and vendor' do
          get :analytics, params: { vendor_id: vendor.id }
          expect(subject.to_a).to contain_exactly([product1.name, 1])
        end
      end

      context 'with orders outside of time range' do
        let!(:order_from_this_week) { create(:completed_order_with_totals) }
        let!(:order_from_this_month) { create(:completed_order_with_totals) }
        let!(:order_from_this_week_product) { order_from_this_week.line_items.first.product }
        let!(:order_from_this_month_product) { order_from_this_month.line_items.first.product }

        before do
          order_from_this_week.update_column(:completed_at, 5.days.ago)
          order_from_this_month.update_column(:completed_at, 25.days.ago)
        end

        it 'returns items sold in last day by default' do
          get :analytics
          expect(subject.to_a).to contain_exactly([product1.name, 1], [product2.name, 1])
        end

        it 'items sold in last 7 days' do
          get :analytics, params: { analytics_time_range: 7 }
          expect(subject.to_a).to contain_exactly([product1.name, 1], [product2.name, 1], [order_from_this_week_product.name, 1])
        end

        it 'items sold in last 30 days' do
          get :analytics, params: { analytics_time_range: 30 }
          expect(subject.to_a).to contain_exactly([product1.name, 1], [product2.name, 1],
                                                  [order_from_this_week_product.name, 1], [order_from_this_month_product.name, 1])
        end
      end

      context 'with more line items and quantity' do
        let!(:order_from_this_week) { create(:completed_order_with_totals) }
        let!(:order_from_this_week_product) { order_from_this_week.line_items.first.product }
        let!(:order1_line_item) { create(:line_item, product: product1, order: order1, quantity: 4) }

        before do
          order_from_this_week.update_column(:completed_at, 5.days.ago)
          order_from_this_week.line_items.first.update_column(:quantity, 3)
          order2.line_items.first.update_column(:quantity, 10)
        end

        it 'returns items sold by summing quantities' do
          get :analytics, params: { analytics_time_range: 7 }
          expect(subject.to_a).to contain_exactly([product1.name, 5], [product2.name, 10], [order_from_this_week_product.name, 3])
        end
      end
    end
  end
end
