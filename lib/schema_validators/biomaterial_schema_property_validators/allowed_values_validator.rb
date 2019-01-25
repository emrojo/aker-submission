# frozen_string_literal: true

module SchemaValidators
  module BiomaterialSchemaPropertyValidators
    class AllowedValuesValidator < BiomaterialSchemaPropertyValidator
      def self.is_applicable?(_property_name, property_data)
        property_data['allowed']
      end

      def validate(labware_index, address, bio_data)
        return true if field_data(bio_data).nil?

        success = true
        enum_items = property_data['allowed']
        if enum_items

          i = if field_data(bio_data)
                enum_items.index { |x| x.casecmp(field_data(bio_data)) == 0 }
              end

          if i.nil?
            success = false
            add_error(labware_index, address, property_name, "The field #{property_name} needs to be one of the following: #{enum_items}.")
          else
            bio_data[property_name] = enum_items[i]
          end
        end
        success
      end
    end
  end
end
