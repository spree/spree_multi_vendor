module Spree
  module Api
    module V2
      module Storefront
        class VendorsController < ::Spree::Api::V2::ResourceController
          private

          def model_class
            Spree::Vendor
          end

          def scope
            Spree::Vendor.approved
          end

          def resource
            scope.friendly.find(params[:id])
          end

          def resource_serializer
            Spree::V2::Storefront::VendorSerializer
          end

          def collection_serializer
            Spree::V2::Storefront::VendorSerializer
          end

          def serializer_params
            super.merge(include_products: action_name == 'show')
          end
        end
      end
    end
  end
end
