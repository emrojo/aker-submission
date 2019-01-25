# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

class Manifest::ProvenanceState::ContentAccessor < Manifest::ProvenanceState::Accessor
  delegate :manifest_schema_field, to: :provenance_state
  delegate :manifest_schema_field_required?, to: :provenance_state
  delegate :manifest_model, to: :provenance_state

  def rebuild?
    (super || !present_structured? || (present_raw? && !!@state[:mapping][:rebuild]))
  end

  def present_mapping?
    (@state[:mapping] && @state[:mapping][:shown])
  end

  def present_raw?
    (state_access.key?(:raw) && !state_access[:raw].nil?)
  end

  def present_structured?
    (state_access.key?(:structured) && !state_access[:structured].nil?)
  end

  class PositionNotFound < StandardError; end
  class LabwareNotFound < StandardError; end
  class PositionDuplicated < StandardError; end
  class WrongNumberLabwares < StandardError; end

  def present?
    super && present_structured?
  end

  def state_access_raw
    state_access && state_access[:raw]
  end

  def build
    {
      raw: state_access_raw,
      structured: state_access_raw && @state[:mapping] ? read_from_raw : read_from_database
    }
  end

  def validate
    if state_access[:structured][:labwares]
      num_labwares_file = state_access[:structured][:labwares].keys.length
      num_labwares_manifest = manifest_model.labwares.count
      if num_labwares_file > num_labwares_manifest
        raise WrongNumberLabwares, "Expected #{num_labwares_manifest} labwares in Manifest but found #{num_labwares_file}."
      elsif num_labwares_file < num_labwares_manifest
        raise WrongNumberLabwares, "Expected #{num_labwares_manifest} labwares in Manifest but could only find #{num_labwares_file}."
      end
    end
  end

  def read_from_database
    returned_list = {}
    manifest_model.labwares.each_with_index do |labware, pos|
      returned_list[pos.to_s] = {}
      next unless labware.contents
      returned_list[pos.to_s][:addresses] = labware.contents.keys.each_with_object({}) do |address, memo_address|
        memo_address[address] = {
          fields: labware.contents[address].keys.each_with_object({}) do |field, memo_field|
            memo_field[field] = { value: labware.contents[address][field] }
          end
        }
      end
    end
    { labwares: returned_list }
  end

  def _find_or_allocate_labware_from_raw(memo, labware_id)
    memo[:labwares] = {} unless memo[:labwares]
    labware_found = memo[:labwares].keys.select { |l| memo[:labwares][l][labware_id_schema_field] == labware_id }[0]
    unless labware_found
      labware_found = memo[:labwares].keys.length
      memo[:labwares][labware_found] = {}
    end
    labware_found
  end

  def labware_id_schema_field
    manifest_schema_field(:labware_id).to_sym
  end

  def read_from_raw
    idx = 0
    state_access[:raw].each_with_object({}) do |row, memo|
      mapped = mapped_row(row)

      validate_labware_existence(mapped, idx)

      labware_id = labware_id(mapped)
      labware_found = _find_or_allocate_labware_from_raw(memo, labware_id)

      validate_position_existence(mapped, idx)

      position = position(mapped)
      build_keys(memo, [:labwares, labware_found, :addresses])
      build_keys(memo, [:labwares, labware_found, :position])
      memo[:labwares][labware_found][:position] = labware_found
      build_keys(memo, [:labwares, labware_found, labware_id_schema_field])
      memo[:labwares][labware_found][labware_id_schema_field] = labware_id

      validate_position_duplication(memo, labware_found, position)

      build_keys(memo, [:labwares, labware_found, :addresses, position, :fields])

      memo[:labwares][labware_found][:addresses][position] = { fields:  mapped }
      idx += 1
    end
  end

  def labware_id(mapped)
    key = manifest_schema_field(:labware_id)
    if mapped[key]
      mapped[key][:value]
    else
      Rails.configuration.manifest_schema_config['default_labware_name_value']
    end
  end

  def position(mapped)
    key = manifest_schema_field(:position)
    if mapped[key]
      mapped[key][:value]
    else
      Rails.configuration.manifest_schema_config['default_position_value']
    end
  end

  def validate_labware_existence(mapped, idx)
    if manifest_schema_field_required?(manifest_schema_field(:labware_id)) && !mapped[manifest_schema_field(:labware_id)]
      raise LabwareNotFound, "This manifest does not have a valid labware id field for the labware at row: #{idx}"
    end
  end

  def validate_position_existence(mapped, idx)
    if manifest_schema_field_required?(manifest_schema_field(:position)) && !mapped[manifest_schema_field(:position)]
      raise PositionNotFound, "This manifest does not have a valid position field for the wells of row: #{idx}"
    end
  end

  def validate_position_duplication(obj, labware_id, position)
    if obj[:labwares][labware_id][:addresses].key?(position)
      raise PositionDuplicated, "Duplicate entry found for #{labware_id}: Position #{position}"
    end
  end

  def mapped_row(row)
    row.keys.each_with_object({}) do |key, memo|
      observed_key = key.to_s
      expected_key = expected_matched_for_observed(observed_key)
      if expected_key
        build_keys(memo, [expected_key, :value])
        memo[expected_key][:value] = row[key]
      end
    end
  end

  def expected_matched_for_observed(key)
    @state[:mapping][:matched].select { |match| match[:observed] == key }.map { |m| m[:expected] }.first
  end
end
