require 'spec_helper'

describe Spree::Admin::BaseController, type: :controller do
  let(:store) { Spree::Store.default }

  describe '#current_vendor' do
    let!(:vendor) { create(:approved_vendor) }
    let(:admin_user) { create(:vendor_user, vendor: vendor) }
    let(:store) { Spree::Store.default }

    subject { controller.current_vendor }

    context 'spree controllers with current store' do
      before do
        allow(controller).to receive(:try_spree_current_user).and_return(admin_user)
        allow(controller).to receive(:current_store).and_return(store)
      end

      context 'current_vendor_id session is set' do
        before { session[:current_vendor_id] = vendor.id }

        it { is_expected.to eq(vendor) }
      end

      context 'current_vendor_id session is not set' do
        it { is_expected.to eq(vendor) }
      end

      context 'store admin user' do
        before do
          store.add_user(admin_user)
        end

        it { is_expected.to be_nil }
      end
    end

    context 'no user' do
      before do
        allow(controller).to receive(:current_store).and_return(store)
      end

      it { is_expected.to be_nil }
    end
  end
end
