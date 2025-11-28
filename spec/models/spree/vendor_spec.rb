require 'spec_helper'

describe Spree::Vendor do
  let(:store) { Spree::Store.default }
  let!(:store_admin) { create(:admin_user) }

  describe 'Validations' do
    let(:vendor) { build(:vendor) }

    describe '#contact_person_cannot_be_store_admin' do
      it 'is invalid' do
        vendor.contact_person_email = store.users.first.email

        expect(vendor).to_not be_valid
        expect(vendor.errors.messages).to include(:contact_person_email)
        expect(vendor.errors.full_messages).to include('Contact person email cannot belong to a store admin')
      end

      it 'is valid with a different email' do
        expect(vendor).to be_valid
      end
    end
  end

  describe 'Callbacks' do
    describe '#create_default_policies' do
      let!(:vendor) { build(:vendor) }

      it 'creates default policies' do
        expect { vendor.save! }.to change(Spree::Policy, :count).by(SpreeMultiVendor::Config[:default_policies].count)
        expect(vendor.policies.pluck(:name)).to contain_exactly(*SpreeMultiVendor::Config[:default_policies].map { |policy| Spree.t(policy) })
      end
    end

    describe 'before_destroy :ensure_can_be_deleted' do
      subject { vendor.destroy }

      let!(:vendor) { create(:approved_vendor) }

      context 'for a vendor with unfulfilled orders' do
        let!(:vendor_order) { create(:vendor_order_ready_to_ship, vendor: vendor) }

        it 'responds with an error' do
          subject

          expect(vendor.reload).to_not be_deleted
          expect(vendor.errors.messages).to eq(base: ["Can't delete a partner with unfulfilled orders"])
        end
      end

      context 'for a vendor with fulfilled orders' do
        let!(:vendor_order) { create(:vendor_shipped_order, vendor: vendor) }

        it 'soft-deletes the vendor' do
          subject
          expect(vendor.reload).to be_deleted
        end
      end
    end

    describe 'after_create' do
      let!(:vendor) { build(:vendor) }

      it 'creates a stock location with default country if no integration is providen' do
        expect { vendor.save! }.to change(Spree::StockLocation, :count).by(1)
        stock_location = Spree::StockLocation.last
        expect(vendor.stock_locations.first).to eq stock_location
        expect(stock_location.country).to eq Spree::Store.default.default_country
      end
    end

    describe 'after_update' do
      let!(:vendor) { create(:vendor) }
      let!(:product_1) { create(:product, vendor: vendor) }
      let!(:product_2) { create(:product, vendor: vendor) }
      let!(:inactive_product) { create(:product, vendor: vendor, status: :draft) }

      it 'updates stock_location names when vendor name changed' do
        old_name = vendor.name
        new_name = 'new vendor name'
        vendor.name = new_name
        expect(vendor.stock_locations.map(&:name).uniq).to eq [old_name]
        vendor.save!
        expect(vendor.stock_locations.map(&:name).uniq).to eq [new_name]
      end
    end
  end

  describe 'Translations' do
    it 'has translatable about field' do
      expect(described_class::TRANSLATABLE_FIELDS).to include(:about)
    end

    it 'supports translations for about' do
      vendor = create(:vendor, about: 'About Vendor')

      I18n.with_locale(:es) do
        vendor.about = 'About Vendor in Spanish'
        vendor.save!
      end

      expect(vendor.about.to_plain_text).to eq('About Vendor')

      I18n.with_locale(:es) do
        expect(vendor.about.to_plain_text).to eq('About Vendor in Spanish')
      end
    end
  end

  describe 'initial state' do
    it 'initial state should be pending' do
      should be_pending
    end
  end

  describe '#start_onboarding', job: true do
    it 'should change state to onboarding' do
      vendor = create(:vendor, state: 'pending')
      vendor.start_onboarding
      expect(vendor).to be_onboarding
      vendor = create(:vendor, state: 'invited')
      vendor.start_onboarding
      expect(vendor).to be_onboarding
    end
  end

  describe '#complete_onboarding', job: true do
    context 'happy path' do
      before do
        allow_any_instance_of(Spree::Vendor).to receive(:accepted?).and_return(true)
        allow_any_instance_of(Spree::Vendor).to receive(:onboarding_completed?).and_return(true)
      end

      it 'should change state to onboarding' do
        vendor = create(:vendor, state: 'pending')
        vendor.complete_onboarding
        expect(vendor.state).to eq('ready_for_review')
        vendor = create(:vendor, state: 'invited')
        vendor.complete_onboarding
        expect(vendor.state).to eq('ready_for_review')
        vendor = create(:vendor, state: 'onboarding')
        vendor.complete_onboarding
        expect(vendor.state).to eq('ready_for_review')
      end
    end

    context 'cannot complete onboarding' do
      before do
        allow_any_instance_of(Spree::Vendor).to receive(:onboarding_completed?).and_return(false)
      end

      it 'should not change state' do
        vendor = create(:vendor, state: 'pending')
        vendor.complete_onboarding
        expect(vendor.state).to eq('pending')
        vendor = create(:vendor, state: 'invited')
        vendor.complete_onboarding
        expect(vendor.state).to eq('invited')
        vendor = create(:vendor, state: 'onboarding')
        vendor.complete_onboarding
        expect(vendor.state).to eq('onboarding')
      end
    end
  end

  context 'mails after state transitions' do
    let!(:vendor) { create(:vendor, state: :pending) }
    let(:mail_double) { double('Mail', deliver_later: true) }
    let!(:marketplace_owner) { create(:admin_user) }

    context 'after Vendor is suspended' do
      before { vendor.approve }

      it 'sends vendor_suspended emails to the vendor owners' do
        expect(Spree::VendorMailer).to receive(:vendor_suspended).with(vendor).and_return(mail_double)
        vendor.suspend
      end
    end

    context 'after Vendor is approved' do
      let!(:vendor_owner) { create(:vendor_user, vendor: vendor) }

      before do
        clear_enqueued_jobs
      end

      it 'sends vendor_approved emails to vendor owners and marketplace owners' do
        expect { vendor.approve && perform_enqueued_jobs }.to change { Spree::VendorMailer.deliveries.count }.by (vendor.users.count + vendor.store.users.count)
        expect(Spree::VendorMailer.deliveries.map(&:to).flatten).to match_array [vendor.users.map(&:email) + vendor.store.users.map(&:email)].flatten
      end

      context 'when there are many marketplace owners' do
        let!(:additional_marketplace_owners) { create_list(:admin_user, 10) }

        it 'sends one vendor_approved email per marketplace owner' do
          expect { vendor.approve && perform_enqueued_jobs }.to change { Spree::VendorMailer.deliveries.count }.by (vendor.users.count + vendor.store.users.count)
        end

        it 'each email has only one recipient' do
          vendor.approve && perform_enqueued_jobs
          expect(Spree::VendorMailer.deliveries.map(&:to).map(&:length).uniq).to eq [1]
        end
      end
    end

    context 'after Vendor is rejected' do
      it 'sends vendor_rejected emails to the vendor owners' do
        expect(Spree::VendorMailer).to receive(:vendor_rejected).with(vendor).and_return(mail_double)
        vendor.reject
      end
    end

    context 'after Vendor starts onboarding' do
      let!(:vendor) { create(:invited_vendor) }

      it 'sends vendor_onboarding_started to marketplace owners' do
        expect { vendor.start_onboarding && perform_enqueued_jobs }.to change(Spree::VendorMailer.deliveries, :count).by(store.users.count + 1)
        expect(Spree::VendorMailer.deliveries.map(&:to).flatten).to contain_exactly(*store.users.pluck(:email), *vendor.contact_person_email)
      end
    end

    context 'after vendor completes onboarding', job: true do
      let!(:vendor) { create(:invited_vendor) }

      before do
        allow(vendor).to receive(:onboarding_completed?).and_return(true)
        clear_enqueued_jobs
      end

      it 'updates vendors state onboarding -> ready_for_review' do
        expect { vendor.save! }.to change(vendor, :state).to('ready_for_review')
      end

      it 'sends vendor_onboarding_completed to store admins' do
        expect { vendor.complete_onboarding! && perform_enqueued_jobs }.to change(Spree::VendorMailer.deliveries, :count).by(store.users.count)
        expect(Spree::VendorMailer.deliveries.map(&:to).flatten).to contain_exactly(*store.users.pluck(:email))
      end
    end
  end

  context 'archiving products when suspended' do
    let!(:vendor) { create(:approved_vendor) }
    let!(:products) { create_list(:product, 5, vendor: vendor) }
    let!(:other_vendor_product) { create(:product, vendor_id: 'other_vendor_id', status: 'active') }

    it 'archives all products of vendor in the background' do
      expect { vendor.suspend }.to enqueue_job(SpreeMultiVendor::Vendors::ArchiveProductsJob).with(vendor.id)
    end

    it 'touches Taxons and Taxonomies' do
      product = products.first
      taxon_ids = product.taxons.map(&:self_and_ancestors).flatten.uniq.map(&:id)
      taxons_updated_at = Spree::Taxon.where(id: taxon_ids).order(:created_at).pluck(:updated_at)
      vendor.suspend

      new_taxons_updated_at = Spree::Taxon.where(id: taxon_ids).order(:created_at).pluck(:updated_at)
      taxons_updated_at.each_with_index do |old_updated_at, index|
        expect(old_updated_at).to be_smaller_than(new_taxons_updated_at[index])
      end
    end
  end

  context 'initial platform_fee' do
    let!(:vendor) { build(:vendor, platform_fee: platform_fee) }

    context 'when platform fee is given' do
      let(:platform_fee) { 17.00 }

      it 'sets it to given value' do
        vendor.save
        expect(vendor.platform_fee).to eq 17.00
      end
    end

    context 'when platform fee is not given' do
      let(:platform_fee) { nil }

      context 'when default store platform fee is set' do
        before { vendor.store.update(preferred_platform_fee: 5.45) }

        it 'sets it to default Store platform_fee' do
          vendor.save
          expect(vendor.platform_fee).to eq 5.45
        end
      end
    end
  end

  describe '#default_stock_location' do
    let!(:vendor) { build(:vendor) }
    let(:store) { Spree::Store.default }

    before { vendor.save! }

    context 'default' do
      it 'returns the vendor stock location' do
        expect(vendor.default_stock_location).to eq(vendor.stock_locations.first)
        expect(vendor.default_stock_location.name).to eq(vendor.name)
        expect(vendor.default_stock_location.vendor).to eq(vendor)
      end
    end
  end
end
