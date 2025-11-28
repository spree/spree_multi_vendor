module SpreeMultiVendor
  module OrderDecorator
    def self.prepended(base)
      base.include Spree::VendorConcern

      base.whitelisted_ransackable_attributes += %w[vendor_id]
      base.whitelisted_ransackable_scopes += %w[splitted with_vendor has_vendor without_vendor]
      base.whitelisted_ransackable_associations += %w[vendor_orders]

      # original order
      base.has_many :vendors, lambda {
                                with_deleted.distinct.reorder("#{Spree::Vendor.table_name}.created_at DESC")
                              }, through: :products, class_name: 'Spree::Vendor'
      base.has_many :vendor_orders, -> { has_vendor }, class_name: 'Spree::Order', foreign_key: 'parent_id'
      base.has_many :vendor_order_vendors, through: :vendor_orders, source: :vendor, class_name: 'Spree::Vendor'
      base.has_many :vendor_order_line_items, through: :vendor_orders, source: :line_items
      base.has_many :vendor_order_variants, through: :vendor_order_line_items, source: :variant
      base.has_many :vendor_order_shipments, through: :vendor_orders, source: :shipments
      base.has_many :vendor_order_payments, through: :vendor_orders, source: :payments
      base.has_many :vendor_order_refunds, through: :vendor_orders, source: :refunds
      base.has_many :vendor_order_adjustments, through: :vendor_orders, source: :adjustments
      base.has_many :vendor_order_line_item_adjustments, through: :vendor_orders, source: :line_item_adjustments
      base.has_many :vendor_order_shipment_adjustments, through: :vendor_orders, source: :shipment_adjustments
      base.has_many :vendor_order_promotions, through: :vendor_orders, source: :promotions
      base.has_many :vendor_order_returns, through: :vendor_orders, source: :returns

      base.has_many :vendor_order_customer_returns, through: :vendor_orders, source: :customer_returns
      base.has_many :vendor_order_marketplace_commissions, through: :vendor_orders, source: :marketplace_commissions

      # vendor order
      base.validates :vendor_id, uniqueness: { scope: :parent_id }, if: :vendor_id?
      base.validates :parent_id, presence: true, if: :vendor_id?
      base.belongs_to :parent, class_name: 'Spree::Order', optional: true, touch: true
      base.has_many :marketplace_commissions,
                    class_name: 'Spree::MarketplaceCommission',
                    foreign_key: :order_id,
                    dependent: :destroy,
                    inverse_of: :order

      base.scope :splitted, -> { where(state: 'splitted') }
      base.scope :not_splitted, -> { where.not(state: 'splitted') }

      base.state_machine.after_transition to: :complete, do: :split_order
      base.state_machine.after_transition to: :canceled, do: :cancel_parent_order

      base.state_machine.event :split do
        transition to: :splitted, from: :complete
      end

      base.money_methods :platform_fee_total, :platform_fee_reverse_total, :vendor_orders_platform_fee_total, :total_after_fees
      base.alias_method :platform_fee_total_money, :display_platform_fee_total
      base.alias_method :platform_fee_reverse_total_money, :display_platform_fee_reverse_total

      base.after_commit :assign_address_to_suborders, on: :update

      def base.webhook_included_relationships
        @webhook_included_relationships ||= Spree::Api::V2::Platform::OrderSerializer.relationships_to_serialize.keys +
          %i[
            line_items.tax_category
            line_items.variant
            line_items.variant.images
            line_items.adjustments
            line_items.inventory_units
            line_items.product
            line_items.product.images

            shipments.stock_location
            shipments.adjustments
            shipments.inventory_units
            shipments.shipping_rates

            order_promotions.promotion
          ]
      end
    end

    def item_additional_tax_before_commission_total
      line_items.sum(&:additional_tax_before_commission_total)
    end

    def additional_tax_before_commission_total
      item_additional_tax_before_commission_total + shipments.sum(&:additional_tax_before_commission_total)
    end

    def parent_order?
      parent.nil?
    end

    def suborder?
      !parent_order?
    end

    # this can be overriden to add custom logic when syncing orders with vendors external stores
    def can_cancel_in_admin?
      true
    end

    # FIXME: all this logic needs to be moved to ability class
    def can_vendor_cancel?
      completed? && !canceled? && vendor.present?
    end

    # we need to overwrite this method as splitted orders usually don't have line items
    def checkout_allowed?
      super || splitted?
    end

    def covered_by_store_credit?
      parent_order = parent || self
      !parent_order.total_minus_store_credits.positive? && parent_order.total_applied_store_credit.positive?
    end

    def total_after_fees
      total_minus_store_credits + platform_fee_total
    end

    def gift_card_total
      parent_order = parent || self
      return 0.to_d unless parent_order.gift_card.present?

      store_credit_ids = payments.store_credits.valid.pluck(:source_id)
      store_credits = Spree::StoreCredit.where(id: store_credit_ids, originator: parent_order.gift_card)

      store_credits.sum(:amount)
    end

    def all_shipments
      @all_shipments ||= if splitted?
                           Spree::Shipment.where(order_id: [id] + vendor_order_ids)
                         else
                           shipments
                         end
    end

    def all_line_items
      @all_line_items = if splitted?
                          Spree::LineItem.where(order_id: [id] + vendor_order_ids)
                        else
                          line_items
                        end
    end

    def all_line_item_adjustments
      @all_line_item_adjustments = if splitted?
                                     Spree::Adjustment.where(id: line_item_adjustment_ids + vendor_order_line_item_adjustment_ids)
                                   else
                                     line_item_adjustments
                                   end
    end

    def all_shipment_adjustments
      @all_shipment_adjustments = if splitted?
                                    Spree::Adjustment.where(id: shipment_adjustment_ids + vendor_order_shipment_adjustment_ids)
                                  else
                                    shipment_adjustments
                                  end
    end

    def all_variants
      @all_variants = if splitted?
                        Spree::Variant.where(id: variant_ids + vendor_order_variant_ids)
                      else
                        variants
                      end
    end

    def all_customer_returns
      @all_customer_returns = if splitted?
                                vendor_order_customer_returns
                              else
                                customer_returns
                              end
    end

    def all_refunds
      @all_refunds = if splitted?
                       vendor_order_refunds
                     else
                       refunds
                     end
    end

    def all_vendors
      @all_vendors = if splitted?
                       vendor_order_vendors
                     else
                       vendors
                     end
    end

    def any_whole_order_discount?
      all_adjustments.
        joins(:promotion_action).
        where(
          Spree::PromotionAction.table_name => {
            type: 'Spree::Promotion::Actions::CreateAdjustment'
          }
        ).any?
    end

    def splitted?
      completed? && (state == 'splitted' || vendor_orders.any?)
    end

    # this is the sum of all vendor orders platform fees
    def vendor_orders_platform_fee_total
      @vendor_orders_platform_fee_total ||= vendor_orders.sum(:platform_fee_total)
    end

    def shipment_shipped
      if suborder?
        queue_webhooks_requests!('suborder.fulfilled')
        parent.queue_webhooks_requests!('order.fulfilled') if parent.all_shipments.all?(&:shipped?)
      else
        queue_webhooks_requests!('order.fulfilled')
      end
    end

    def canceled_by(user, canceled_at = nil)
      canceled_at ||= Time.current

      if parent_order? && splitted?
        transaction do
          vendor_orders.find_each do |vo|
            vo.canceled_by(user, canceled_at) if vo.can_cancel?
          end
        end
      else
        super(user, canceled_at)
      end
    end

    def split!
      update_columns(state: :splitted, updated_at: Time.current)
    end

    def assign_address_to_suborders
      return unless vendor_orders.any?

      if saved_change_to_ship_address_id?
        vendor_order_shipments.update_all(address_id: ship_address.id, updated_at: Time.current)
        vendor_orders.update_all(ship_address_id: ship_address.id, updated_at: Time.current)
      elsif saved_change_to_bill_address_id?
        vendor_orders.update_all(bill_address_id: bill_address.id, updated_at: Time.current)
      end
    end

    def deliver_vendor_order_notification_email?
      !store.test_mode? && suborder? && !confirmation_delivered
    end

    def deliver_vendor_order_notification_email
      return unless deliver_vendor_order_notification_email?

      vendor.users.each do |member|
        Spree::OrderMailer.with(order: self, recipient: member).vendor_order_confirm_email.deliver_later(wait: 15.seconds)
      end

      update_column(:confirmation_delivered, true)
    end

    private

    def recalculate_totals
      update_with_updater! if parent_order?
    end

    def split_order
      SpreeMultiVendor::Orders::SplitByVendorJob.set(wait: 30.seconds).perform_later(id) if vendors.any?
    end

    # TODO: we should move this to a background worker
    def cancel_parent_order
      return if parent_order?

      # 1 sub-order, we want to cancel the parent order
      # or all sub-orders are cancelled, we want to cancel the parent order
      if (parent.vendor_order_ids == [id] || parent.vendor_orders.all?(&:canceled?)) && parent.line_items.empty?
        parent.update_columns(
          state: :canceled,
          updated_at: Time.current,
          canceled_at: canceled_at,
          shipment_state: :canceled,
          payment_state: :void
        )

        parent.queue_webhooks_requests!('order.cancelled')
      else
        # not yet all sub-orders are cancelled, we want to mark the parent order as partially cancelled
        parent.update_columns(state: :partially_canceled, updated_at: Time.current)
      end
    end
  end
end

Spree::Order.prepend(SpreeMultiVendor::OrderDecorator) if Spree::Order.included_modules.exclude?(SpreeMultiVendor::OrderDecorator)
