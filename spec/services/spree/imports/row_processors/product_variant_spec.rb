require 'spec_helper'

RSpec.describe Spree::Imports::RowProcessors::ProductVariant, type: :service do
  subject { described_class.new(row) }

  let(:store) { Spree::Store.default }
  let(:vendor) { create(:approved_vendor) }
  let(:vendor_user) { create(:vendor_user, vendor: vendor) }
  let(:import) { create(:product_import, owner: vendor, user: vendor_user) }
  let(:row) { create(:import_row, import: import, data: row_data.to_json) }
  let(:csv_row_headers) { Spree::ImportSchemas::Products.new.headers }
  let(:variant) { subject.process! }

  before do
    import.create_mappings
  end

  # Matches how our production import will pass attributes
  def csv_row_hash(attrs = {})
    csv_row_headers.index_with { |header| attrs[header] }
  end

  let(:row_data) do
    csv_row_hash(
      'slug' => 'denim-shirt',
      'name' => 'Denim Shirt',
      'status' => 'draft',
      'description' => 'Adipisci sapiente velit nihil ullam. Placeat cumque ipsa cupiditate velit magni sapiente mollitia dolorum. Veritatis esse illo eos perferendis. Perspiciatis vel iusto odio eveniet quam officia quidem. Fugiat a ipsum tempore optio accusantium autem in fugit.',
      'price' => '62.99',
      'currency' => 'USD',
      'weight' => '0.0',
      'inventory_count' => '100',
      'inventory_backorderable' => 'true',
      'tags' => 'ECO, Gold'
    )
  end

  context 'when importing a master variant product row' do
    it 'creates a product and associates it to the vendor' do
      expect { subject.process! }.to change(Spree::Product, :count).by(1)
      product = variant.product
      expect(product).to be_persisted
      expect(product.slug).to eq 'denim-shirt'
      expect(product.name).to eq 'Denim Shirt'
      expect(variant.vendor).to eq vendor
    end
  end

  context 'fails when trying to update an existing non-vendor product' do
    let!(:product) { create(:product, slug: 'denim-shirt', name: 'Denim Shirt', stores: [store]) }

    it 'fails to update the product' do
      expect { subject.process! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
