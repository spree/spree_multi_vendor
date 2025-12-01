require 'spec_helper'

RSpec.describe Spree::Admin::VendorSettingsController, type: :controller do
  stub_authorization!
  render_views

  let!(:vendor) { create(:vendor, name: 'John Doe') }
  let(:admin_user) { create(:vendor_user, vendor: vendor) }

  describe 'GET #edit' do
    it 'renders the edit template' do
      get :edit
      expect(response).to render_template(:edit)
    end

    context 'when there is no current vendor' do
      before do
        allow(controller).to receive(:current_vendor).and_return(nil)
      end

      it 'redirects to the root path' do
        get :edit
        expect(response).to redirect_to(spree.admin_dashboard_path)
      end
    end
  end

  describe 'PUT #update' do
    subject { put :update, params: { vendor: { name: 'Jane Moe' } } }

    it 'updates the vendor' do
      subject

      expect(vendor.reload.name).to eq('Jane Moe')
      expect(response).to redirect_to(spree.edit_admin_vendor_settings_path)
    end

    context 'when there is no current vendor' do
      before do
        allow(controller).to receive(:current_vendor).and_return(nil)
      end

      it 'redirects to the root path' do
        subject

        expect(response).to redirect_to(spree.admin_dashboard_path)
      end
    end
  end
end
