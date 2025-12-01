module SpreeMultiVendor
  module OptionValueDecorator
    def self.prepended(base)
      #
      # Scopes
      #
      base.scope :for_option_types, ->(option_types) { where(option_type: option_types) }
      base.scope :distinct_by_id, lambda {
        select(
          [
            "#{base.table_name}.*",
            "MIN(#{base.table_name}.position) as min_position"
          ]
        ).group(:id).reorder(min_position: :asc)
      }

      base.scope :for_option_name_combinations, lambda { |combinations|
        joins(:option_type).where(
          Arel::Nodes::In.new(
            Arel::Nodes::Grouping.new(
              [
                Spree::OptionType.arel_table[:name],
                base.arel_table[:name]
              ]
            ),
            combinations.map do |options|
              Arel::Nodes::Grouping.new(
                [
                  Arel::Nodes.build_quoted(options[0].parameterize.strip),
                  Arel::Nodes.build_quoted(options[1].parameterize.strip)
                ]
              )
            end
          )
        )
      }
    end
  end
end

Spree::OptionValue.prepend(SpreeMultiVendor::OptionValueDecorator)
