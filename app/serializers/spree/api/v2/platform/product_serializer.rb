module Spree
  module Api
    module V2
      module Platform
        class ProductSerializer < BaseSerializer
          include DisplayMoneyHelper

          set_type :product

          attributes(*(Spree::Product.json_api_columns + ['sku', 'barcode', 'external_id']))

          attribute :purchasable do |product|
            product.purchasable?
          end

          attribute :in_stock do |product|
            product.in_stock?
          end

          attribute :backorderable do |product|
            product.backorderable?
          end

          attribute :available do |product|
            product.available?
          end

          attribute :currency do |_product, params|
            params[:currency] || Spree::Store.default.default_currency
          end

          attribute :price do |product, params|
            price(product, params[:currency])
          end

          attribute :display_price do |product, params|
            display_price(product, params[:currency])
          end

          attribute :compare_at_price do |product, params|
            compare_at_price(product, params[:currency])
          end

          attribute :display_compare_at_price do |product, params|
            display_compare_at_price(product, params[:currency])
          end

          belongs_to :tax_category

          has_one :primary_variant,
                  object_method_name: :master,
                  id_method_name: :master_id,
                  record_type: :variant,
                  serializer: :variant

          has_one :default_variant,
                  object_method_name: :default_variant,
                  id_method_name: :default_variant_id,
                  record_type: :variant,
                  serializer: :variant

          has_many :variants
          has_many :option_types
          has_many :product_properties

          # all images from all variants
          has_many :images,
                   object_method_name: :variant_images,
                   id_method_name: :variant_image_ids,
                   record_type: :image,
                   serializer: :image

          # Attributes added by Vendo
          attribute :tags, &:tag_list
          attribute :labels, &:label_list

          belongs_to :vendor
          has_many :taxons, serializer: :taxon, record_type: :taxon

          belongs_to :shipping_category
        end
      end
    end
  end
end
