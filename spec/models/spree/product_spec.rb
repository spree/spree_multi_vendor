require 'spec_helper'

RSpec.describe Spree::Product, type: :model do
  let(:store) { Spree::Store.default }
  let(:vendor) { create(:vendor) }

  it 'has correct ransackable attributes' do
    expect(described_class.whitelisted_ransackable_attributes).to include('vendor_id')
  end

  context 'Callbacks' do
    let(:product) { create(:product, stores: [store], vendor: vendor) }

    describe '#auto_match_taxons' do
      let(:product) { create(:product) }

      context 'when product is created' do
        let(:product) { build(:product) }

        it 'calls #auto_match_taxons' do
          expect(product).to receive(:auto_match_taxons).at_least(:once)
          product.save!
        end

        context 'with automatic taxons' do
          let!(:taxon) { create(:automatic_taxon, store: Spree::Store.default) }

          it 'enqueues Spree::Products::AutoMatchTaxonsJob' do
            expect { product.save! }.to have_enqueued_job(Spree::Products::AutoMatchTaxonsJob).exactly(:once)
          end
        end

        context 'without automatic taxons' do
          before do
            product.stores.first.taxons.automatic.delete_all
          end

          it 'does not enqueue Spree::Products::AutoMatchTaxonsWorker' do
            expect { product.save! }.to_not have_enqueued_job(Spree::Products::AutoMatchTaxonsJob)
          end
        end
      end

      context 'when product is updated' do
        context 'when tags are updated' do
          it 'calls #auto_match_taxons' do
            expect(product.reload).to receive(:auto_match_taxons)
            product.update!(tag_list: 'eco, vegan')
          end
        end

        context 'when available_on is updated' do
          it 'calls #auto_match_taxons' do
            expect(product.reload).to receive(:auto_match_taxons)
            product.update!(available_on: 2.days.from_now)
          end
        end

        context 'when any other attribute is updated' do
          it 'doesnt call #auto_match_taxons' do
            expect(product.reload).not_to receive(:auto_match_taxons)
            product.update!(name: 'new name')
          end
        end
      end

      context 'when product is touched' do
        it 'doesnt call #auto_match_taxons' do
          expect(product.reload).not_to receive(:auto_match_taxons)
          product.touch
        end
      end
    end

    describe '#update_vendor_products_count' do
      it 'updates vendor products count' do
        product
        expect { create(:product, stores: [store], vendor: vendor) }.to change { vendor.reload.products_count }.by(1)
        expect { product.destroy }.to change { vendor.reload.products_count }.by(-1)
      end

      it 'updates vendor updated_at' do
        product = build(:product, stores: [store], vendor: vendor)

        expect { product.save! }.to change(vendor, :updated_at)
        expect { product.destroy }.to change { vendor.reload.updated_at }
      end
    end
  end

  describe '#restore' do
    let!(:product) { create :product_in_stock }

    before do
      product.destroy!
      create(:product_in_stock, name: product.name, stores: product.stores, vendor: product.vendor)
    end

    it 'restores product' do
      expect { product.restore }.to change { product.reload.deleted_at }.to(nil)
      expect(product.slug).not_to include('deleted')
    end
  end
end
