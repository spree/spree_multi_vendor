module Spree
  module V2
    module Storefront
      class VendorSerializer < BaseSerializer
        include Spree::Api::V2::PublicMetafieldsConcern

        set_type :vendor

        attributes :name, :slug

        attribute :email do |vendor|
          vendor.contact_person_email
        end

        attribute :about_us do |vendor|
          vendor.about.to_plain_text
        end

        attribute :about_us_html do |vendor|
          vendor.about.to_s
        end

        attribute :logo_url do |vendor|
          url_helpers.cdn_image_url(vendor.logo.attachment) if vendor.logo.present? && vendor.logo.attached?
        end

        attribute :cover_photo_url do |vendor|
          url_helpers.cdn_image_url(vendor.cover_photo.attachment) if vendor.cover_photo.present? && vendor.cover_photo.attached?
        end

        has_many :products,
                 record_type: :product,
                 if: proc { |_vendor, params| params && params[:include_products] == true },
                 &:active_products

        has_many :policies, serializer: Spree::Api::Dependencies.storefront_policy_serializer.constantize, record_type: :policy
      end
    end
  end
end
