module SpreeMultiVendor
  module ProductDecorator
    def self.prepended(base)
      base.extend Spree::DisplayMoney
      base.money_methods :commission_amount

      base.whitelisted_ransackable_attributes += %w[vendor_id]
      base.whitelisted_ransackable_associations += %w[products_external_categories products_external_product_type]

      base.state_machine.event :pause do
        transition to: :paused
      end

      base.has_many :vendor_shipping_methods, ->(product) { with_vendor(product.vendor_id) }, through: :shipping_category, source: :shipping_methods
      base.has_many :marketplace_shipping_methods, -> { without_vendor }, through: :shipping_category, source: :shipping_methods

      base.after_commit :update_vendor_products_count, on: %i[create destroy]

      base.delegate :name, to: :vendor, prefix: true, allow_nil: true
    end

    def shipping_methods
      vendor_id.present? ? vendor_shipping_methods : marketplace_shipping_methods
    end

    def restore_with_variants_only
      return unless paranoia_destroyed?

      ApplicationRecord.transaction do
        restore

        uniq_deleted_variants = variants_including_master.only_deleted.uniq(&:external_id)
        live_variant_external_ids = variants_including_master.pluck(:external_id)

        variants_to_restore = uniq_deleted_variants.reject { |variant| variant.external_id.in?(live_variant_external_ids) }
        variants_to_restore.each(&:restore)
      end
    end

    def commission_rate
      @commission_rate ||= platform_fee.presence || vendor&.platform_fee
    end

    def commission_amount
      return if commission_rate.blank?
      return if price.blank?

      @commission_amount ||= price * (commission_rate / 100)
    end

    def update_vendor_products_count
      return unless vendor.present?

      vendor.update_columns(products_count: vendor.products.count, updated_at: Time.current)
    end

    def external?
      defined?(external_id) && external_id.present?
    end

    private

    def ensure_not_in_complete_orders
      return if external_id.present?

      super
    end
  end
end

Spree::Product.prepend(SpreeMultiVendor::ProductDecorator)
