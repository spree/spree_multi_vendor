module SpreeMultiVendor
  module TaxonRules
    class Vendor < Spree::TaxonRule
      def apply(scope)
        if match_policy == 'is_equal_to'
          scope.where(vendor_id: value)
        elsif match_policy == 'is_not_equal_to'
          scope.where.not(vendor_id: value)
        else
          scope
        end
      end

      def vendor
        @vendor ||= Spree::Vendor.with_deleted.find_by(id: value)
      end
    end
  end
end
