require 'spec_helper'

RSpec.describe Spree::Admin::TaxonsController, type: :controller do
  stub_authorization!
  render_views

  let(:store) { Spree::Store.default }
  let(:taxonomy) { create(:taxonomy, store: store) }

  describe 'GET #select_options' do
    before { Spree::Taxon.destroy_all }

    let!(:automatic_taxon) { create(:taxon, taxonomy: taxonomy, name: 'Automatic Taxon', automatic: true) }
    let!(:manual_taxon) { create(:taxon, taxonomy: taxonomy, name: 'Manual Taxon', automatic: false) }

    context 'with a vendor user' do
      let(:admin_user) { create(:vendor_user, vendor: vendor) }
      let(:vendor) { create(:approved_vendor) }

      before do
        allow(controller).to receive(:current_ability).and_return(Spree::Dependencies.ability_class.constantize.new(admin_user))
        allow(controller).to receive(:authorize_admin).and_return(true)
      end

      it 'returns only manual taxons' do
        get :select_options

        expect(JSON.parse(response.body)).to eq([{ 'id' => manual_taxon.id, 'name' => manual_taxon.pretty_name }])
        expect(assigns.keys).not_to include('object')
      end
    end
  end
end
