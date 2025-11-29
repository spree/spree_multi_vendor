require 'spec_helper'

RSpec.describe Spree::Admin::ImportsController, type: :controller do
  stub_authorization!
  render_views

  let(:vendor) { create(:approved_vendor) }
  let(:admin_user) { create(:vendor_user, vendor: vendor) }
  let(:store) { Spree::Store.default }

  let(:attachment) { Rack::Test::UploadedFile.new(File.join(Spree::Core::Engine.root, 'spec/fixtures/files', 'products_import.csv'), 'text/csv') }
  let(:csv_content) { File.read(File.join(Spree::Core::Engine.root, 'spec/fixtures/files', 'products_import.csv')) }

  before do
    allow(controller).to receive(:current_vendor).and_return(vendor)
    allow(controller).to receive(:try_spree_current_user).and_return(admin_user)
  end

  describe 'GET #new' do
    it 'renders the new template' do
      get :new, params: { import: { type: 'Spree::Imports::Products' } }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
      expect(assigns(:object)).to be_a_new(Spree::Import)
    end
  end

  describe 'POST #create' do
    let(:import_params) { { type: Spree::Import.available_types.first.to_s, attachment: attachment } }

    it 'creates a new import and redirects to show' do
      expect {
        post :create, params: { import: import_params }
      }.to change(Spree::Import, :count).by(1)

      import = Spree::Import.last
      expect(response).to redirect_to(spree.admin_import_path(import))
      expect(import.user).to eq(admin_user)
      expect(import.owner).to eq(vendor)
      expect(import.type).to eq(Spree::Import.available_types.first.to_s)
      expect(import.attachment).to be_attached
      expect(import.attachment.filename.to_s).to eq('products_import.csv')
    end
  end
end
