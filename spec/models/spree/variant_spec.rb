require 'spec_helper'

describe Spree::Variant do
  describe 'disable_sku_validation?' do
    it 'returns true' do
      expect(Spree::Variant.new.disable_sku_validation?).to be_truthy
    end
  end
end
