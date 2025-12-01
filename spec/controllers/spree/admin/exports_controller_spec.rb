require 'spec_helper'

RSpec.describe Spree::Admin::ExportsController, type: :controller do
  stub_authorization!
  render_views

  let(:vendor) { create(:approved_vendor) }
  let(:admin_user) { create(:vendor_user, vendor: vendor) }
  let(:store) { Spree::Store.default }

  before do
    allow(controller).to receive(:current_vendor).and_return(vendor)
    allow(controller).to receive(:try_spree_current_user).and_return(admin_user)
  end

  describe '#new' do
    it 'renders the new template' do
      get :new, params: { export: { type: 'Spree::Exports::Orders' } }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
      expect(assigns(:object)).to be_a_new(Spree::Export)
    end
  end

  describe '#create' do
    let(:export_params) do
      {
        export: {
          type: 'Spree::Exports::Orders',
          search_params: { 'created_at_gt' => 1.week.ago.to_s }.to_json
        }
      }
    end

    it 'creates a new export with vendor_id set' do
      expect {
        post :create, params: export_params
      }.to change(Spree::Export, :count).by(1)

      export = Spree::Export.last
      expect(export.vendor).to eq(vendor)
      expect(export.user).to eq(admin_user)
      expect(export.type).to eq('Spree::Exports::Orders')
      expect(export.search_params).to be_present
      expect(response).to redirect_to(spree.admin_exports_path)
    end

    it 'sets flash message after successful creation' do
      post :create, params: export_params
      expect(flash[:success]).to eq(Spree.t('admin.export_created'))
    end
  end

  describe '#index' do
    let(:other_vendor) { create(:approved_vendor) }
    let!(:vendor_export) { create(:product_export, vendor: vendor, user: admin_user, store: store) }
    let!(:other_vendor_export) { create(:product_export, vendor: other_vendor, store: store) }
    let!(:admin_export) { create(:product_export, vendor: nil, store: store) }

    it 'lists only exports belonging to current vendor' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)

      expect(assigns(:collection)).to include(vendor_export)
      expect(assigns(:collection)).not_to include(other_vendor_export)
      expect(assigns(:collection)).not_to include(admin_export)
    end
  end

  describe '#show' do
    let(:export) { create(:product_export, vendor: vendor, user: admin_user, store: store) }

    before do
      allow_any_instance_of(Spree::Exports::Products).to receive_message_chain(:attachment, :url).and_return('http://example.com/test.csv')
    end

    subject { get :show, params: { id: export.id } }

    it 'downloads the export' do
      subject
      expect(response).to have_http_status(:see_other)
      expect(response.headers['Location']).to eq(export.attachment.url)
    end
  end
end
