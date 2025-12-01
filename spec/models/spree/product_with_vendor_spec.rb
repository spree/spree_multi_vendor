require 'timecop'

describe Spree::Product do
  let(:vendor) { create(:vendor) }
  let(:product) { create(:product, vendor: vendor) }

  it 'does not touch vendor after update' do
    time = Time.current + 1.hour
    product
    Timecop.freeze(time) do
      expect { product.touch }.not_to change { vendor.reload.updated_at }
    end
  end
end
