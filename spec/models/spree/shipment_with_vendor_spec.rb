require 'spec_helper'

describe Spree::Shipment, type: :model do
  context 'vendorized shipment' do
    it 'assigns vendor from stock location' do
      stock_location = create(:stock_location, vendor: create(:vendor))
      shipment = create(:shipment, stock_location: stock_location)
      expect(shipment.vendor).to eq(stock_location.vendor)
    end
  end
end
