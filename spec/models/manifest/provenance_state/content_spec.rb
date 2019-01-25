# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Manifest::ProvenanceState::ContentAccessor' do
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
        'plate_id' => {
          'show_on_form' => true, 'friendly_name' => 'Plate Id', 'required' => false,
          'field_name_regex' => '^plate', 'type' => 'string'
        },
        'position' => {
          'show_on_form' => true, 'friendly_name' => 'Position', 'required' => false,
          'field_name_regex' => 'position', 'type' => 'string'
        }
      }
    }
  end

  let(:default_position_value) do
    Rails.configuration.manifest_schema_config['default_position_value']
  end
  let(:default_labware_name_value) do
    Rails.configuration.manifest_schema_config['default_labware_name_value']
  end

  let(:labware_name) do
    Rails.configuration.manifest_schema_config['field_labware_name']
  end
  let(:position) do
    Rails.configuration.manifest_schema_config['field_position']
  end
  let(:user) { create :user }
  let(:provenance_state) { Manifest::ProvenanceState.new(manifest, user) }
  let(:content_accessor) { provenance_state.content }

  let(:manifest) do
    manifest = create :manifest
    manifest.update_attributes(no_of_labwares_required: 1)
    manifest
  end
  context '#apply error checks' do
    context 'with a manifest with a labware that contains the same position twice' do
      let(:manifest_content) do
        [
          { 'plate_id' => 'Labware 1', 'position' => 'A:1', 'supplier_name' => 'InGen' },
          { 'plate_id' => 'Labware 1', 'position' => 'A:1', 'supplier_name' => 'InGen2' }
        ]
      end

      let(:mapping) do
        {
          expected: [],
          observed: [], matched: [
            { expected: 'supplier_plate_name', observed: 'plate_id' },
            { expected: 'supplier_name', observed: 'supplier_name' },
            { expected: 'position', observed: 'position' }
          ]
        }
      end

      before do
        allow(content_accessor).to receive(:manifest_schema_field_required?).with('position').and_return(true)
        allow(content_accessor).to receive(:manifest_schema_field_required?).with('supplier_plate_name').and_return(true)
      end

      it 'raises PositionDuplicated' do
        expect do
          content_accessor.apply(mapping: mapping, content: { raw: manifest_content })
        end.to raise_error(Manifest::ProvenanceState::ContentAccessor::PositionDuplicated)
      end
    end

    context 'when the labware is not defined in some entries of the manifest' do
      let(:manifest_content) do
        [
          { 'plate_id' => 'Labware 1', 'supplier_name' => 'InGen', 'position' => 'A:1' },
          { 'supplier_name' => 'InGen2', 'position' => 'A:1' }
        ]
      end

      context 'with a manifest that contains a plate_id match' do
        let(:mapping) do
          {
            expected: [],
            observed: [], matched: [
              { expected: 'supplier_plate_name', observed: 'plate_id' },
              { expected: 'supplier_name', observed: 'supplier_name' },
              { expected: 'position', observed: 'position' }
            ]
          }
        end

        context 'when the plate_id is required' do
          before do
            allow(content_accessor).to receive(:manifest_schema_field_required?).with('position').and_return(true)
            allow(content_accessor).to receive(:manifest_schema_field_required?).with('supplier_plate_name').and_return(true)
          end

          it 'raises LabwareNotFound error' do
            expect do
              content_accessor.apply(mapping: mapping, content: { raw: manifest_content })
            end.to raise_error(Manifest::ProvenanceState::ContentAccessor::LabwareNotFound)
          end
        end
      end
    end

    context 'when the position is not defined in some entries of the manifest' do
      let(:manifest_content) do
        [
          { 'plate_id' => 'Labware 1', 'supplier_name' => 'InGen', 'position' => 'A:1' },
          { 'plate_id' => 'Labware 1', 'supplier_name' => 'InGen2' }
        ]
      end

      context 'with a manifest that contains a position match' do
        let(:mapping) do
          {
            expected: [],
            observed: [], matched: [
              { expected: 'supplier_plate_name', observed: 'plate_id' },
              { expected: 'supplier_name', observed: 'supplier_name' },
              { expected: 'position', observed: 'position' }
            ]
          }
        end

        context 'when the position is required' do
          before do
            allow(content_accessor).to receive(:manifest_schema_field_required?).with('position').and_return(true)
            allow(content_accessor).to receive(:manifest_schema_field_required?).with('supplier_plate_name').and_return(true)
          end

          it 'raises PositionNotFound error' do
            expect do
              content_accessor.apply(mapping: mapping, content: { raw: manifest_content })
            end.to raise_error(Manifest::ProvenanceState::ContentAccessor::PositionNotFound)
          end
        end
      end
    end
  end
  context '#apply' do
    before do
      allow(content_accessor).to receive(:manifest_schema_field_required?).with('supplier_plate_name').and_return(false)
      allow(content_accessor).to receive(:manifest_schema_field_required?).with('position').and_return(false)
      content_accessor.apply(schema: schema, mapping: mapping, content: { raw: manifest_content })
    end
    context 'with an empty manifest' do
      let(:mapping) do
        {
          expected: %w[is_tumour scientific_name taxon_id supplier_name gender],
          observed: [], matched: []
        }
      end
      let(:manifest_content) { [] }
      it 'does not generate any content' do
        expect(content_accessor.state[:content]).to include(raw: [], structured: {})
      end
    end
    context 'with a manifest that does not contain plate id match' do
      let(:mapping) do
        {
          expected: [],
          observed: [], matched: [
            { expected: 'position', observed: 'position' },
            { expected: 'supplier_name', observed: 'supplier_name' }
          ]
        }
      end
      let(:manifest_content) do
        [
          { 'supplier_plate_name' => 'Labware 1', 'position' => 'A:1', 'supplier_name' => 'InGen' },
          { 'supplier_plate_name' => 'Labware 1', 'position' => 'B:1', 'supplier_name' => 'InGen' }
        ]
      end

      it 'does generate content setting plate id for the plate as DEFAULT_LABWARE_NAME_VALUE' do
        expect(content_accessor.state[:content]).to include(structured: { labwares: {
                                                              0 => {
                                                                position: 0,
                                                                supplier_plate_name: default_labware_name_value.to_s,
                                                                addresses: {
                                                                  'A:1' => { fields: { 'position' => { value: 'A:1' }, 'supplier_name' => { value: 'InGen' } } },
                                                                  'B:1' => { fields: { 'position' => { value: 'B:1' }, 'supplier_name' => { value: 'InGen' } } }
                                                                }
                                                              }
                                                            } })
      end
    end
    context 'with a manifest that does not contain position match' do
      let(:mapping) do
        {
          expected: [],
          observed: [], matched: [
            { expected: 'plate_id', observed: 'plate_id' },
            { expected: 'supplier_name', observed: 'supplier_name' }
          ]
        }
      end
      let(:manifest_content) do
        [
          'plate_id' => 'Labware 1', 'position' => 'A:1', 'supplier_name' => 'InGen'
        ]
      end
      context 'when the position is not required' do
        it 'does generate content setting position for the plate' do
          expect(content_accessor.state[:content]).to include(structured: { labwares: {
                                                                0 => {
                                                                  position: 0, supplier_plate_name: 'default',
                                                                  addresses: {
                                                                    default_position_value.to_s => { fields: { 'plate_id' => { value: 'Labware 1' }, 'supplier_name' => { value: 'InGen' } } }
                                                                  }
                                                                }
                                                              } })
        end
      end
    end

    context 'with a manifest that does not contain either plate_id or position match' do
      let(:mapping) do
        {
          expected: [],
          observed: [], matched: [
            { expected: 'supplier_name', observed: 'supplier_name' }
          ]
        }
      end
      let(:manifest_content) do
        [
          'plate_id' => 'Labware 1', 'position' => 'A:1', 'supplier_name' => 'InGen'
        ]
      end

      it 'does generate content setting position and plate_id as default' do
        expect(content_accessor.state[:content]).to include(structured: { labwares: {
                                                              0 => {
                                                                position: 0, supplier_plate_name: 'default',
                                                                addresses: {
                                                                  default_position_value.to_s => { fields: { 'supplier_name' => { value: 'InGen' } } }
                                                                }
                                                              }
                                                            } })
      end
    end

    context 'with a matching of plate id using a different attribute than plate_id' do
      let(:mapping) do
        {
          expected: [],
          observed: [], matched: [
            { expected: 'supplier_plate_name', observed: 'supplier_name' },
            { expected: 'position', observed: 'position' },
            { expected: 'supplier_name', observed: 'plate_id' }
          ]
        }
      end
      let(:manifest_content) do
        [
          { 'plate_id' => 'Labware 1', 'position' => 'A:1', 'supplier_name' => 'InGen' },
          { 'plate_id' => 'Labware 2', 'position' => 'B:1', 'supplier_name' => 'InGen' }
        ]
      end

      it 'does recognise the right plate id attribute to perform the translation' do
        expect(content_accessor.state[:content]).to include(structured: { labwares: {
                                                              0 => {
                                                                position: 0, supplier_plate_name: 'InGen',
                                                                addresses: {
                                                                  'A:1' => { fields: { 'position' => { value: 'A:1' }, 'supplier_plate_name' => { value: 'InGen' }, 'supplier_name' => { value: 'Labware 1' } } },
                                                                  'B:1' => { fields: { 'position' => { value: 'B:1' }, 'supplier_plate_name' => { value: 'InGen' }, 'supplier_name' => { value: 'Labware 2' } } }
                                                                }
                                                              }
                                                            } })
      end
    end

    context 'with a manifest that contains all the fields' do
      let(:mapping) do
        {
          expected: [],
          observed: [], matched: [
            { expected: 'position', observed: 'position' }, { expected: 'supplier_plate_name', observed: 'plate_id' },
            { expected: 'is_tumour', observed: 'is_tumour' }, { expected: 'scientific_name', observed: 'scientific_name' },
            { expected: 'taxon_id', observed: 'taxon_id' }, { expected: 'supplier_name', observed: 'supplier_name' },
            { expected: 'gender', observed: 'gender' }
          ]
        }
      end
      let(:manifest_content) do
        [
          'plate_id' => 'Labware 1', 'position' => 'A:1', 'is_tumour' => 'tum', 'scientific_name' => 'sci',
          'taxon_id' => '123', 'supplier_name' => 'sup', 'gender' => 'male'
        ]
      end
      it 'does generate the content' do
        expect(content_accessor.state[:content]).to include(structured: { labwares: {
                                                              0 => {
                                                                position: 0, supplier_plate_name: 'Labware 1',
                                                                addresses: {
                                                                  'A:1' => { fields: {
                                                                    'position' => { value: 'A:1' }, 'supplier_plate_name' => { value: 'Labware 1' },
                                                                    'is_tumour' => { value: 'tum' }, 'scientific_name' => { value: 'sci' },
                                                                    'taxon_id' => { value: '123' }, 'supplier_name' => { value: 'sup' }, 'gender' => { value: 'male' }
                                                                  } }
                                                                }
                                                              }
                                                            } })
      end
    end
    context 'with a manifest that contains some fields' do
      let(:mapping) do
        {
          expected: %w[taxon_id supplier_name gender],
          observed: ['unknown_value'],
          matched: [
            { expected: 'position', observed: 'position' }, { expected: 'supplier_plate_name', observed: 'plate_id' },
            { expected: 'is_tumour', observed: 'is_tumour' },
            { expected: 'scientific_name', observed: 'scientific_name' }
          ]
        }
      end
      let(:manifest_content) do
        [
          'plate_id' => 'Labware 1', 'position' => 'A:1', 'is_tumour' => '', 'scientific_name' => '', 'unknown_value' => ''
        ]
      end
      it 'returns only the list of matched fields' do
        expect(content_accessor.state[:content]).to include(structured: {
                                                              labwares: { 0 => {
                                                                position: 0, supplier_plate_name: 'Labware 1',
                                                                addresses: {
                                                                  'A:1' => { fields: {
                                                                    'position' => { value: 'A:1' }, 'supplier_plate_name' => { value: 'Labware 1' },
                                                                    'is_tumour' => { value: '' }, 'scientific_name' => { value: '' }
                                                                  } }
                                                                }
                                                              } }
                                                            })
      end
    end
  end
end
