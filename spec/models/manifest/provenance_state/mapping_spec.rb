# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Manifest::ProvenanceState::Mapping' do
  let(:schema) do
    {
      'show_on_form' => %w[taxon_id scientific_name supplier_name gender is_tumour],
      'type' => 'object',
      'properties' => {
        'is_tumour' => {
          'show_on_form' => true, 'friendly_name' => 'Tumour?', 'required' => false,
          'field_name_regex' => '^(?:is[-_ ]+)?tumou?r\\??$', 'type' => 'string'
        },
        'scientific_name' => {
          'show_on_form' => true, 'friendly_name' => 'Scientific Name', 'required' => false,
          'field_name_regex' => '^scientific(?:[-_ ]*name)?$', 'type' => 'string'
        },
        'taxon_id' => {
          'show_on_form' => true, 'friendly_name' => 'Taxon ID', 'required' => false,
          'field_name_regex' => '^taxon(?:[-_ ]*id)?$', 'type' => 'string'
        },
        'supplier_name' => {
          'show_on_form' => true, 'friendly_name' => 'Supplier Name', 'required' => true,
          'field_name_regex' => '^supplier[-_ ]*name$', 'type' => 'string'
        },
        'gender' => {
          'show_on_form' => true, 'friendly_name' => 'Gender', 'required' => false,
          'field_name_regex' => '^(?:gender|sex)$', 'type' => 'string'
        },
        'unneeded_field' => {
          'show_on_form' => false, 'friendly_name' => 'Unneeded', 'required' => false,
          'field_name_regex' => 'unneeded_field', 'type' => 'string'
        }

      }
    }
  end

  let(:labware_name) do
    Rails.configuration.manifest_schema_config['field_labware_name']
  end
  let(:position) do
    Rails.configuration.manifest_schema_config['field_position']
  end
  let(:user) { create :user }
  let(:provenance_state) { Manifest::ProvenanceState.new(manifest, user) }
  let(:mapping_accessor) { provenance_state.mapping }

  let(:manifest) { create :manifest }
  context '#apply' do
    before do
      allow(provenance_state.schema).to receive(:manifest_schema).and_return(schema)
      mapping_accessor.apply(content: { raw: manifest_content })
    end

    context 'with an empty manifest' do
      let(:manifest_content) { [] }
      it 'does not match anything' do
        expect(mapping_accessor.state[:mapping]).to include(
          expected: %w[is_tumour scientific_name taxon_id supplier_name gender],
          observed: [], matched: []
        )
      end
    end
    context 'with a manifest that contains all the fields' do
      let(:manifest_content) do
        [
          'is_tumour' => '', 'scientific_name' => '', 'taxon_id' => '',
          'supplier_name' => '', 'gender' => '', 'unneeded_field' => 'not needed'
        ]
      end
      it 'does match all needed fields' do
        expect(mapping_accessor.state[:mapping]).to include(
          expected: [],
          observed: ['unneeded_field'], matched: [
            { expected: 'is_tumour', observed: 'is_tumour' }, { expected: 'scientific_name', observed: 'scientific_name' },
            { expected: 'taxon_id', observed: 'taxon_id' }, { expected: 'supplier_name', observed: 'supplier_name' },
            { expected: 'gender', observed: 'gender' }
          ]
        )
      end
    end
    context 'with a manifest that contains some fields' do
      let(:manifest_content) do
        [
          'is_tumour' => '', 'scientific_name' => '', 'unknown_value' => ''
        ]
      end
      it 'returns the list of matched pairs and the list of columsn unmatched in both sides' do
        expect(mapping_accessor.state[:mapping]).to include(
          expected: %w[taxon_id supplier_name gender],
          observed: ['unknown_value'],
          matched: [
            { expected: 'is_tumour', observed: 'is_tumour' }, { expected: 'scientific_name', observed: 'scientific_name' }
          ]
        )
      end
    end
    context 'when there are columns in the schema without a regular expression' do
      let(:schema) do
        { 'properties' => {
          'column_to_show' => { 'show_on_form' => true, 'field_name_regex' => 'column_to_show' },
          'column_to_hide' => { 'show_on_form' => true }
        } }
      end
      let(:manifest_content) do
        [
          'column_to_show' => '', 'column_to_hide' => ''
        ]
      end
      it 'does not expect to find them, but matches the others' do
        expect(mapping_accessor.state[:mapping]).to include(
          expected: [],
          observed: ['column_to_hide'],
          matched: [
            { expected: 'column_to_show', observed: 'column_to_show' }
          ]
        )
      end
    end
    context 'when there are columns in the schema that must not be shown in the form' do
      let(:schema) do
        { 'properties' => {
          'column_to_show' => { 'show_on_form' => true, 'field_name_regex' => 'column_to_show' },
          'column_to_hide' => { 'show_on_form' => false, 'field_name_regex' => 'column_to_hide' }
        } }
      end
      let(:manifest_content) do
        [
          'column_to_show' => '', 'column_to_hide' => ''
        ]
      end

      it 'does not expect to find them, but matches the others' do
        expect(mapping_accessor.state[:mapping]).to include(
          expected: [],
          observed: ['column_to_hide'],
          matched: [
            { expected: 'column_to_show', observed: 'column_to_show' }
          ]
        )
      end

      context 'when any of this columns not to shown are actually required by the schema' do
        let(:schema) do
          { 'properties' => {
            'column_to_show' => { 'show_on_form' => true, 'field_name_regex' => 'column_to_show' },
            'hidden_required_column' => { 'show_on_form' => false, 'field_name_regex' => 'hidden_required_column',
                                          'required' => true }
          } }
        end

        it 'expects to find them and tries to map them' do
          expect(mapping_accessor.state[:mapping]).to include(
            expected: ['hidden_required_column'],
            observed: ['column_to_hide'],
            matched: [
              { expected: 'column_to_show', observed: 'column_to_show' }
            ]
          )
        end
      end
    end

    context 'validate' do
      let(:manifest_content) do
        [
          'column_to_show' => '', 'column_to_hide' => ''
        ]
      end
      context 'when any shown field is not mapped' do
        let(:schema) do
          { 'properties' => {
            'column_to_show' => { 'show_on_form' => true, 'field_name_regex' => 'showcol' },
            'column_to_hide' => { 'show_on_form' => false, 'field_name_regex' => 'column_to_hide',
                                  'required' => true }
          } }
        end

        it 'does show the mapping tool (shown: true)' do
          expect(mapping_accessor.state[:mapping]).to include(
            shown: true,
            expected: ['column_to_show'],
            observed: ['column_to_show'],
            matched: [{ observed: 'column_to_hide', expected: 'column_to_hide' }]
          )
        end
      end

      context 'when all shown field are mapped' do
        let(:schema) do
          { 'properties' => {
            'column_to_show' => { 'show_on_form' => true, 'field_name_regex' => 'column_to_show' },
            'column_to_hide' => { 'show_on_form' => false, 'field_name_regex' => 'column_to_hide',
                                  'required' => true }
          } }
        end

        it 'does not show the mapping tool (shown: false)' do
          expect(mapping_accessor.state[:mapping]).to include(
            shown: false,
            expected: [],
            observed: [],
            matched: [{ expected: 'column_to_show', observed: 'column_to_show' },
                      { expected: 'column_to_hide', observed: 'column_to_hide' }]
          )
        end
      end

      context 'when any required field is not mapped' do
        let(:schema) do
          { 'properties' => {
            'column_to_show' => { 'show_on_form' => true, 'field_name_regex' => 'column_to_show' },
            'hidden_required_column' => { 'show_on_form' => false, 'field_name_regex' => 'hidden_required_column',
                                          'required' => true }
          } }
        end

        it 'does not validate the mapping' do
          expect(mapping_accessor.state[:mapping]).to include(
            valid: false,
            expected: ['hidden_required_column'],
            observed: ['column_to_hide'],
            matched: [
              { expected: 'column_to_show', observed: 'column_to_show' }
            ]
          )
        end
      end
      context 'when all required fields are mapped' do
        let(:schema) do
          { 'properties' => {
            'column_to_show' => { 'show_on_form' => true, 'field_name_regex' => 'column_to_show' },
            'hidden_required_column' => { 'show_on_form' => false, 'field_name_regex' => 'column_to_hide',
                                          'required' => true }
          } }
        end

        it 'validates the mapping' do
          expect(mapping_accessor.state[:mapping]).to include(
            valid: true,
            expected: [],
            observed: [],
            matched: [

              { expected: 'column_to_show', observed: 'column_to_show' },
              { expected: 'hidden_required_column', observed: 'column_to_hide' }
            ]
          )
        end
      end
    end

    context 'with the default schema data' do
      let(:manifest_content) do
        [
          { plate_id: 'plate_1', well_position: 'A:1', supplier_name: 'supplier name 1',
            donor_id: 'donor id 1', gender: 'male', scientific_name: 'Triticum turgidum subsp. durum',
            phenotype: 'Red', tumour: 'normal', tissue_type: 'blood', taxon_id: '4567' },
          { plate_id: 'plate_2', well_position: 'A:1', supplier_name: 'supplier name 2',
            donor_id: 'donor id 2', gender: 'male', scientific_name: 'Triticum turgidum subsp. durum',
            phenotype: 'Green', tumour: 'normal', tissue_type: 'dna', taxon_id: '4567' },
          { plate_id: 'plate_3', well_position: 'A:1', supplier_name: 'supplier name 3', donor_id: 'donor id 3',
            gender: 'male', scientific_name: 'Triticum turgidum subsp. durum', phenotype: 'Yellow',
            tumour: 'normal', tissue_type: 'cells', taxon_id: '4567' }
        ]
      end
      let(:schema_with_plate_id_and_pos) do
        schema2 = schema.dup
        schema2['properties'].merge!('plate_id' => {
                                       'show_on_form' => true, 'friendly_name' => 'Plate id', 'required' => true,
                                       'field_name_regex' => 'plate_id', 'type' => 'string'
                                     },
                                     'position' => {
                                       'show_on_form' => true, 'friendly_name' => 'Well position', 'required' => true,
                                       'field_name_regex' => 'positio', 'type' => 'string'
                                     })
        schema2
      end
      it 'matches plate id and position' do
        allow(provenance_state.schema).to receive(:manifest_schema).and_return(schema_with_plate_id_and_pos)
        mapping_accessor.apply(content: { raw: manifest_content })
        expect((mapping_accessor.state[:mapping][:matched].select do |e|
          ((((e[:expected] == 'plate_id') && (e[:observed] == 'plate_id'))) ||
          (((e[:expected] == 'position') && (e[:observed] == 'well_position'))))
        end).count == 2).to eq(true)
      end
    end
  end
end
