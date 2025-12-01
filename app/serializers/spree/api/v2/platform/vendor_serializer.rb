module Spree
  module Api
    module V2
      module Platform
        class VendorSerializer < BaseSerializer
          include Spree::Api::V2::PublicMetafieldsConcern

          set_type :vendor

          attributes :name, :slug, :contact_person_email, :public_metadata

          attribute :about_us do |vendor|
            vendor.about.to_plain_text
          end

          has_many :policies, serializer: Spree::Api::Dependencies.storefront_policy_serializer.constantize, record_type: :policy
        end
      end
    end
  end
end
