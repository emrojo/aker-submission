# frozen_string_literal: true

require 'rails_helper'

require 'schema_validators'

RSpec.describe SchemaValidators::BiomaterialSchemaValidator do
  let(:schema) do
    {
      'required' => %w[REQUIRED_FREE REQUIRED_ENUM],
      'properties' => {
        'OPTIONAL' => {
          'required' => false
        },
        'taxon_id' => {
          'required' => false
        },
        'scientific_name' => {
          'required' => false
        },
        'REQUIRED_FREE' => {
          'required' => true
        },
        'REQUIRED_ENUM' => {
          'required' => true,
          'allowed' => %w[ALPHA BETA GAMMA]
        }
      }
    }.as_json
  end
  let(:validator) { SchemaValidators::BiomaterialSchemaValidator.new(schema.as_json) }

  context '#properties_to_validate' do
    it 'returns the properties from the loaded json schema' do
      expect(validator.properties_to_validate).to eq(%w[OPTIONAL taxon_id scientific_name REQUIRED_FREE REQUIRED_ENUM])
    end
  end
  context '#validators_for' do
    it 'returns the list of valid validators for the field specified' do
      expect(validator.validators_for('OPTIONAL').length).to eq(0)
      expect(validator.validators_for('taxon_id').map(&:class)).to eq([
                                                                        SchemaValidators::BiomaterialSchemaPropertyValidators::TaxonIdValidator
                                                                      ])
      expect(validator.validators_for('scientific_name').length).to eq(0)
      expect(validator.validators_for('REQUIRED_FREE').length).to eq(1)
      expect(validator.validators_for('REQUIRED_FREE').map(&:class)).to eq([
                                                                             SchemaValidators::BiomaterialSchemaPropertyValidators::RequiredFieldValidator
                                                                           ])
      expect(validator.validators_for('REQUIRED_ENUM').length).to eq(2)
      expect(validator.validators_for('REQUIRED_ENUM').map(&:class)).to eq([
                                                                             SchemaValidators::BiomaterialSchemaPropertyValidators::RequiredFieldValidator,
                                                                             SchemaValidators::BiomaterialSchemaPropertyValidators::AllowedValuesValidator
                                                                           ])
    end
  end
end
