require 'spec_helper'

RSpec.describe Spree::Orders::SplitByVendor do
  let(:store) { Spree::Store.default }

  let(:user) { create(:user) }
  let(:parent_order) do
    create(:completed_order_with_totals,
           special_instructions: 'Hi there',
           last_ip_address: '127.0.0.1',
           without_line_items: true,
           user: user,
           bill_address: create(:address, user: user),
           ship_address: create(:address, user: user))
  end

  let!(:vendor) { create(:approved_vendor) }
  let!(:vendor_2) { create(:approved_vendor) }
  let!(:vendor_user) { create(:vendor_user, vendor: vendor, email: vendor.contact_person_email) }
  let!(:vendor_user_2) { create(:vendor_user, vendor: vendor_2, email: vendor_2.contact_person_email) }

  let(:tax_category) { create(:tax_category) }
  let(:tax_category_2) { create(:tax_category) }
  let(:product) { create(:product_in_stock, tax_category: tax_category, vendor: vendor, price: 90.0) }
  let(:product_2) { create(:product_in_stock, tax_category: tax_category, vendor: vendor, price: 49.0) }
  let(:product_3) { create(:product_in_stock, tax_category: tax_category_2, vendor: vendor_2, price: 100.0) }

  let(:variant) { product.default_variant }
  let(:variant_2) { product_2.default_variant }
  let(:variant_3) { product_3.default_variant }

  let!(:line_item) { create(:line_item, order: parent_order, product: product, price: product.price) }
  let!(:line_item_2) { create(:line_item, order: parent_order,  product: product_2, price: product_2.price) }
  let!(:line_item_3) { create(:line_item, order: parent_order,  product: product_3, price: product_3.price) }

  let(:order_item_total) { 239.to_d }
  let(:order_promo_total) { -10.to_d }
  let(:order_shipment_total) { 20.to_d }
  let(:order_additional_tax_total) { 13.9.to_d }
  let(:order_total) { order_item_total + order_promo_total + order_shipment_total + order_additional_tax_total }

  let(:vendor_item_total) { 139.to_d }
  let(:vendor_shipment_total) { 10.to_d }
  let(:vendor_additional_tax_total) { 13.9.to_d }
  let(:vendor_platform_fee_total) { -0.3 * vendor_item_total }
  let(:vendor_order_total) { vendor_item_total + vendor_shipment_total }

  let(:vendor_2_item_total) { 100.to_d }
  let(:vendor_2_shipment_total) { 10.to_d }
  let(:vendor_2_additional_tax_total) { 0.0.to_d }
  let(:vendor_2_platform_fee_total) { -0.3 * vendor_2_item_total }
  let(:vendor_2_order_total) { vendor_2_item_total + vendor_2_shipment_total }

  before do
    parent_order.shipments.destroy_all
  end

  context 'when not parent order' do
    let(:vendor_order) { build(:order, parent: parent_order, vendor: vendor) }

    it 'returns failed' do
      expect(subject.call(order: vendor_order).success?).to be(false)
    end

    it 'does not send order confirmation email to vendor' do
      expect { subject.call(order: vendor_order) }.not_to change(Spree::OrderMailer.deliveries, :count)
    end
  end

  context 'when already all splitted' do
    let!(:vendor_order) { create(:order, parent: parent_order, vendor: vendor) }
    let!(:vendor_order_2) { create(:order, parent: parent_order, vendor: vendor_2) }

    it 'returns failed' do
      expect(subject.call(order: parent_order).success?).to be(false)
    end

    it 'does not send order confirmation email to vendor' do
      expect { subject.call(order: vendor_order) }.not_to change(Spree::OrderMailer.deliveries, :count)
    end
  end

  it 'calls the Spree::Orders::CreateVendorOrder service per vendor' do
    create_vendor_order_service = double(:create_vendor_order_service, call: nil)
    allow(Spree::Orders::CreateVendorOrder).to receive(:new).and_return(create_vendor_order_service)

    subject.call(order: parent_order)

    expect(create_vendor_order_service).to have_received(:call).twice
  end

  it 'splits the parent order into vendor_orders per supplier' do
    create(:payment, order: parent_order)

    subject.call(order: parent_order)

    expect(parent_order.vendor_orders.count).to eq(2)
  end

  it 'sends vendor order confirmation email to each vendor' do
    create(:payment, order: parent_order)
    clear_enqueued_jobs
    subject.call(order: parent_order)
    perform_enqueued_jobs(except: Spree::Addresses::GeocodeAddressJob)

    mail_1 = Spree::OrderMailer.deliveries.find { |delivery| delivery.to.include?(vendor.contact_person_email) }
    vendor_order_1 = vendor.orders.last

    expect(mail_1).to be_present
    expect(mail_1.subject).to eq('New Order Received')
    expect(mail_1.body).to include(vendor_order_1.number)

    mail_2 = Spree::OrderMailer.deliveries.find { |delivery| delivery.to.include?(vendor_2.contact_person_email) }
    vendor_order_2 = vendor_2.orders.last

    expect(mail_2).to be_present
    expect(mail_2.subject).to eq('New Order Received')
    expect(mail_2.body).to include(vendor_order_2.number)
  end

  it 'stores correct totals' do
    setup_order_with_everything

    expect(parent_order.vendor_orders.count).to eq(0)

    check_totals

    subject.call(order: parent_order)
    parent_order.reload

    expect(parent_order.vendor_orders.count).to eq(2)
    expect(parent_order.vendor_orders.pluck(:platform_fee_total)).to contain_exactly(vendor_platform_fee_total, vendor_2_platform_fee_total)
    expect(parent_order.vendor_orders.pluck(:additional_tax_total)).to contain_exactly(vendor_additional_tax_total, vendor_2_additional_tax_total)

    # vendor order includes no tax in order total
    expect(parent_order.vendor_orders.pluck(:total)).to contain_exactly(vendor_order_total, vendor_2_order_total)

    check_totals
  end

  it 'keeps taxes in the vendor order' do
    setup_order_with_everything

    expect(parent_order.vendor_orders.count).to eq(0)

    check_totals

    subject.call(order: parent_order)
    parent_order.reload

    expect(parent_order.vendor_orders.count).to eq(2)
    expect(parent_order.vendor_order_line_item_adjustments.count).to eq(2)

    expect(parent_order.vendor_order_line_item_adjustments.pluck(:amount)).to match_array [9.0, 4.9]

    check_totals
  end

  private

  def check_totals
    expect(parent_order.item_total).to eq(order_item_total)
    expect(parent_order.total).to eq(order_total)
    expect(parent_order.adjustment_total).to eq(order_promo_total + order_additional_tax_total)
    expect(parent_order.payment_total).to eq(order_total)
    expect(parent_order.shipment_total).to eq(order_shipment_total)
    expect(parent_order.additional_tax_total).to eq(order_additional_tax_total)
    expect(parent_order.promo_total).to eq(order_promo_total)
    expect(parent_order.included_tax_total).to eq(0.0)
    expect(parent_order.taxable_adjustment_total).to eq(order_promo_total)
    expect(parent_order.non_taxable_adjustment_total).to eq(0.0)
    expect(parent_order.platform_fee_total).to eq(0.0)
  end

  def setup_order_with_everything
    create_promotion
    create_shipments
    create_tax_rates
    update_parent_order

    create(:payment, order: parent_order, amount: parent_order.total, state: :completed)
  end

  def update_parent_order
    parent_order.reload
    parent_order.update_line_item_prices!
    parent_order.create_tax_charge!
    parent_order.update_with_updater!
  end

  def create_tax_rates
    create(:tax_rate, amount: 0.1, tax_category: tax_category, zone: parent_order.tax_zone)
  end

  def create_shipments
    create(:shipment, order: parent_order, cost: 10, stock_location: variant.stock_items.first.stock_location, vendor: vendor, state: 'ready')
    create(:shipment, order: parent_order, cost: 10, stock_location: variant_3.stock_items.first.stock_location, vendor: vendor_2, state: 'ready')
  end

  def create_promotion
    parent_order.update!(state: 'cart')
    create(:promotion, :with_order_adjustment, weighted_order_adjustment_amount: 10, stores: [store]).activate(order: parent_order)
    parent_order.update!(state: 'complete')
  end
end
