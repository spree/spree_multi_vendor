module Spree::Api::V2::Platform
  class VendorsController < ResourceController
    VENDOR_EVENT_NAMES = %i[invite start_onboarding complete_onboarding approve reject suspend].freeze

    VENDOR_EVENT_NAMES.each do |event_name|
      define_method event_name do
        resource.send(event_name)
        if resource.errors.empty?
          render_serialized_payload { serialize_resource(resource) }
        else
          render_error_payload(resource.errors)
        end
      end
    end

    def model_class
      Spree::Vendor
    end
  end
end
