module Spree
  class Vendor < Spree.base_class
    extend FriendlyId
    friendly_id :name, use: :slugged

    include Spree::Metadata
    include Spree::Webhooks::HasWebhooks
    include Spree::Vendors::Onboarding
    include Spree::UserManagement
    include Spree::Metafields
    include Spree::TranslatableResource

    include PgSearch::Model if defined?(PgSearch)

    audited only: %i[name state billing_email contact_person_email] if defined?(Audited)

    DEFAULT_VENDOR_ROLE = 'vendor'

    #
    # Magic ✨
    #
    acts_as_paranoid

    #
    # Attachments
    #
    has_one_attached :logo, service: Spree.public_storage_service_name
    has_one_attached :square_logo, service: Spree.public_storage_service_name
    has_one_attached :cover_photo, service: Spree.public_storage_service_name

    #
    # Translations
    #
    TRANSLATABLE_FIELDS = %i[about].freeze
    translates(*TRANSLATABLE_FIELDS, column_fallback: !Spree.always_use_translations?)

    #
    # Rich Texts
    #
    translates :about, backend: :action_text

    #
    # Preferences
    #
    preference :shipping_rates_confirmed, :boolean, default: false

    #
    # Virtual attributes
    #
    attribute :invited_by_email
    attribute :skip_global_onboarding_tasks, default: false, type: :boolean

    #
    # Callbacks
    #
    before_validation :set_platform_fee_from_store, on: :create

    after_create :add_contact_person_to_users
    after_create :create_stock_location
    after_create :create_default_policies
    after_create :set_state_to_invited
    after_update :update_stock_location_names

    before_destroy :ensure_can_be_deleted

    #
    # Validations
    #
    validates :name, presence: true
    validates :contact_person_email, presence: true,
                                     uniqueness: { scope: spree_base_uniqueness_scope },
                                     email: true,
                                     if: :skip_contact_person_email_validation
    validate :contact_person_cannot_be_store_admin
    validates :logo, :square_logo, :cover_photo, content_type: Rails.application.config.active_storage.web_image_content_types

    #
    # Associations
    #
    belongs_to :invited_by, class_name: Spree.admin_user_class.to_s, foreign_key: :invited_by_id
    belongs_to :returns_address, class_name: 'Spree::ReturnsAddress', dependent: :destroy, autosave: true
    belongs_to :billing_address, class_name: 'Spree::BillingAddress', dependent: :destroy, autosave: true

    accepts_nested_attributes_for :returns_address, :billing_address

    has_many :products, class_name: 'Spree::Product', dependent: :destroy_async
    has_many :active_products, -> { active }, class_name: 'Spree::Product'
    has_many :variants, class_name: 'Spree::Variant', through: :products, source: :variants_including_master
    has_many :classifications, class_name: 'Spree::Classification', through: :products, source: :classifications
    has_many :taxons, class_name: 'Spree::Taxon', through: :classifications
    has_many :digital_links, class_name: 'Spree::DigitalLink', through: :variants
    has_many :policies, class_name: 'Spree::Policy', dependent: :destroy, as: :owner

    has_many :orders, class_name: 'Spree::Order'
    has_many :line_items, class_name: 'Spree::Shipment', through: :orders
    has_many :shipments, class_name: 'Spree::Shipment', through: :orders
    has_many :payments, class_name: 'Spree::Payment', through: :orders
    has_many :return_authorizations, class_name: 'Spree::ReturnAuthorization', through: :orders
    has_many :reimbursements, class_name: 'Spree::Reimbursement', through: :orders
    has_many :adjustments, class_name: 'Spree::Adjustment', through: :orders
    has_many :refunds, class_name: 'Spree::Refund', through: :payments

    has_many :stock_locations, class_name: 'Spree::StockLocation', dependent: :destroy
    has_many :stock_items, class_name: 'Spree::StockItem', through: :stock_locations
    has_many :shipping_methods, class_name: 'Spree::ShippingMethod', dependent: :destroy

    #
    # State machine
    #
    state_machine :state, initial: :pending do
      event :invite do
        transition from: :pending, to: :invited
      end
      event :cancel do
        transition from: :invited, to: :canceled
      end
      event :start_onboarding do
        transition from: [:pending, :invited], to: :onboarding
      end
      event :complete_onboarding do
        transition from: [:pending, :invited, :onboarding], to: :ready_for_review, if: lambda { |vendor|
          vendor.onboarding_completed?
        }
      end
      event :approve do
        transition from: [:pending, :invited, :onboarding, :suspended, :ready_for_review, :rejected], to: :approved
      end
      event :reject do
        transition from: [:pending, :invited, :onboarding, :suspended, :ready_for_review], to: :rejected
      end
      event :suspend do
        transition from: [:pending, :invited, :onboarding, :suspended, :ready_for_review, :approved, :rejected], to: :suspended
      end

      after_transition to: :suspended, do: :archive_products
      after_transition to: [:rejected, :suspended], do: :send_state_transition_email
      after_transition to: :approved, do: :after_approved
      after_transition to: :onboarding, do: %i[after_onboarding_started]
      after_transition to: :ready_for_review, do: :after_onboarding_completed
      after_transition to: :canceled, do: ->(vendor) { vendor.destroy }
    end

    #
    # Scopes
    #
    scope :invited, -> { where(state: 'invited') }
    scope :onboarding, -> { where(state: 'onboarding') }
    scope :approved, -> { where(state: 'approved') }
    scope :ready_for_review, -> { where(state: 'ready_for_review') }
    scope :with_access_to_ui, -> { where.not(state: 'pending') } # even rejected or suspended vendors should have access to UI

    if defined?(PgSearch)
      pg_search_scope :search_by_name, against: :name
    else
      scope :search_by_name, ->(name) { where('name ILIKE ?', "%#{name}%") }
    end

    #
    # Ransack configuration
    #
    self.whitelisted_ransackable_attributes = %w[name state products_count sales_total commission_total created_at]
    self.whitelisted_ransackable_scopes = %w[invited accepted onboarding approved ready_for_review]
    self.whitelisted_ransackable_associations = %w[store]

    #
    # Money methods 💸
    #
    extend DisplayMoney
    money_methods :sales_total, :commission_total

    def can_be_deleted?
      orders.not_shipped.empty?
    end

    def not_approved?
      state != 'approved'
    end

    def can_approve?
      super && onboarding_completed?
    end

    def skip_contact_person_email_validation
      false
    end

    def default_stock_location
      @default_stock_location ||= Rails.cache.fetch("vendor-default-stock-location/#{cache_key_with_version}") do
        stock_locations.active.order_default.first || ActiveRecord::Base.connected_to(role: :writing) { create_stock_location }
      end
    end

    def weight_unit
      store.preferred_weight_unit
    end

    def stripe_payouts_schedule
      case payouts_schedule_interval
      when 'daily'
        { interval: 'daily' }
      when 'weekly'
        { interval: 'weekly', weekly_anchor: 'monday' }
      when 'manual'
        { interval: 'manual' }
      else
        { interval: 'monthly', monthly_anchor: 1 }
      end
    end

    def contact_person
      @contact_person ||= Spree.admin_user_class.find_by(email: contact_person_email)
    end

    def display_name
      name
    end

    def email
      billing_email || contact_person_email
    end

    def store
      if respond_to?(:tenant)
        tenant.default_store
      else
        Spree::Store.current
      end
    end

    def default_user_role
      Spree::Role.find_or_create_by!(name: DEFAULT_VENDOR_ROLE)
    end

    def returns_policy
      policies.find_by(name: Spree.t('returns_policy'))
    end

    private

    def ensure_can_be_deleted
      return if can_be_deleted?

      errors.add(:base, :cannot_destroy_vendor)
      throw(:abort)
    end

    def create_stock_location
      stock_location = stock_locations.where(name: name).first_or_initialize
      stock_location.country ||= store.default_country
      stock_location.save!
      stock_location
    end

    def create_default_policies
      SpreeMultiVendor::Config[:default_policies].each do |policy|
        vendor_policy = policies.find_or_initialize_by(name: Spree.t(policy))
        vendor_policy.save!
      end
    end

    def update_stock_location_names
      return unless saved_changes&.include?(:name)

      stock_locations.each do |stock_location|
        stock_location.update(name: name)
      end
    end

    def add_contact_person_to_users
      # user exists, adding to the resource
      if contact_person.present? && contact_person.persisted?
        add_user(contact_person, default_user_role)
      else
        inviter = invited_by || store.users.first

        return if inviter.blank?

        # we need to invite the contact person
        invitations.create!(
          inviter: inviter,
          email: contact_person_email,
          role: default_user_role
        )
      end
    end

    def set_state_to_invited
      return if invited_by_email == false

      invite
    end

    def set_platform_fee_from_store
      self.platform_fee ||= store&.preferred_platform_fee
    end

    def send_state_transition_email(transition)
      Spree::VendorMailer.send("vendor_#{transition.to}", self).deliver_later
    end

    def after_onboarding_started
      # notify store admins
      store.users.each do |admin|
        Spree::VendorMailer.with(vendor: self, recipient: admin).vendor_onboarding_started.deliver_later
      end
    end

    def after_onboarding_completed
      # notify store admins
      store.users.each do |admin|
        Spree::VendorMailer.with(vendor: self, recipient: admin).vendor_onboarding_completed.deliver_later
      end
    end

    def after_approved
      # notify vendor users
      users.each do |owner|
        Spree::VendorMailer.with(vendor: self, recipient: owner).vendor_approved.deliver_later
      end

      # notify store admins
      store.users.each do |admin|
        Spree::VendorMailer.with(vendor: self, recipient: admin).vendor_approved.deliver_later
      end
    end

    def archive_products
      SpreeMultiVendor::Vendors::ArchiveProductsJob.perform_later(id)
    end

    def pause_products
      SpreeMultiVendor::Vendors::PauseProductsJob.perform_later(id)
    end

    def activate_products
      SpreeMultiVendor::Vendors::ActivateProductsJob.perform_later(id)
    end

    def contact_person_cannot_be_store_admin
      return if contact_person_email.blank?
      return unless store.users.find_by(email: contact_person_email.downcase).present?

      errors.add(:contact_person_email, :cannot_be_store_admin)
    end
  end
end
