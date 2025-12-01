require 'spec_helper'

RSpec.describe SpreeMultiVendor::PermissionSets::VendorUser, type: :model do
  let(:vendor) { create(:approved_vendor) }
  let(:vendor_user) { create(:vendor_user, vendor: vendor) }

  let(:ability) { Spree::Ability.new(vendor_user) }

  subject(:permission_set) { described_class.new(ability) }

  before { permission_set.activate! }

  describe '#activate!' do
    context 'orders' do
      let(:order) { create(:vendor_order, vendor: vendor) }

      it 'cannot create' do
        expect(ability).not_to be_able_to :create, order
      end

      it 'can admin' do
        expect(ability).to be_able_to :admin, order
      end

      it 'can show' do
        expect(ability).to be_able_to :show, order
      end

      it 'can index' do
        expect(ability).to be_able_to :index, order
      end

      it 'can edit' do
        expect(ability).to be_able_to :edit, order
      end

      it 'cannot update' do
        expect(ability).to be_able_to :update, order
      end

      it 'can cart' do
        expect(ability).to be_able_to :cart, order
      end
    end

    context 'stock_locations' do
      let(:other_vendor) { create(:approved_vendor) }
      let(:stock_location) { create(:stock_location, vendor: vendor) }
      let(:stock_location_other_vendor) { create(:stock_location, vendor: other_vendor) }

      it 'can manage stock locations that are related to the vendor' do
        expect(ability).to be_able_to(:manage, stock_location)
        expect(ability).to_not be_able_to(:manage, stock_location_other_vendor)
      end
    end

    context 'Spree::Taxon' do
      let(:category) { create(:taxon) }

      it 'can admin' do
        expect(ability).to be_able_to(:admin, category)
      end

      it 'can select_options' do
        expect(ability).to be_able_to(:select_options, category)
      end
    end

    context 'Spree::PaymentMethod' do
      let!(:store) { Spree::Store.default }
      let!(:payment_method) { create(:payment_method, stores: [store]) }

      it 'cannot create payment method' do
        expect(ability).to_not be_able_to(:manage, payment_method)
      end
    end

    context 'Spree::ShippingMethod' do
      let!(:country_zone) { create(:zone, name: 'CountryZone') }
      let!(:shipping_method) { create(:shipping_method, zones: [country_zone]) }

      it 'can create shipping method' do
        expect(ability).to be_able_to(:create, shipping_method)
      end
    end

    context 'Spree::Product' do
      let!(:store) { Spree::Store.default }
      let!(:product) { create(:product, vendor: vendor, stores: [store]) }

      it 'can create products' do
        expect(ability).to be_able_to(:create, product)
      end

      it 'cannot manage commision' do
        expect(ability).to_not be_able_to(:manage_commission, product)
      end

      it 'cannot activate product' do
        expect(ability).to_not be_able_to(:activate, product)
      end
    end

    context 'Spree::Address' do
      let!(:address) { create(:address, user: create(:user)) }

      it 'cannot create address' do
        expect(ability).to_not be_able_to(:create, address)
      end
    end
  end
end
