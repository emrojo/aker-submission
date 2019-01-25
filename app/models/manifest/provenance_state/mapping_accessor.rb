# frozen_string_literal: true

class Manifest::ProvenanceState::MappingAccessor < Manifest::ProvenanceState::Accessor
  delegate :manifest_schema, to: :provenance_state

  def validate
    unless state_access.key?(:valid)
      state_access[:valid] = required_unmatched_fields.empty?
      state_access[:hasUnmatched] = (!shown_unmatched_fields.empty? && !observed_keys.empty?)
      state_access[:shown] = state_access[:hasUnmatched]
      # state_access[:rebuild] = state_access.key?(:rebuild) ? state_access[:rebuild] : state_access[:shown]
      # state_access[:rebuild] = state_access.key?(:rebuild) ? state_access[:rebuild] : state_access[:shown]
      # debugger if state_access[:hasUnmatched]
    end
  end

  def valid?
    state_access.key?(:valid) && state_access[:valid]
  end

  def rebuild?
    (super && @state[:content] && !@state[:content][:structured] && @state[:content][:raw])
  end

  def build
    perform_mapping
  end

  def initial_mapping
    {
      observed: observed_keys.dup,
      expected: [],
      matched: []
    }
  end

  def field_requires_mapping?(expected_properties)
    ((expected_properties['required']) || (expected_properties['show_on_form'] && expected_properties['field_name_regex']))
  end

  def map_field(memo, expected_key, expected_properties, observed_keys)
    found = observed_keys.detect do |observed_key|
      observed_key.strip.match(expected_properties['field_name_regex'])
    end
    if found
      memo[:matched].push(expected: expected_key, observed: found)
      memo[:observed].reject! { |observed_key| (observed_key == found) }
    else
      memo[:expected].push(expected_key)
    end
  end

  def perform_mapping
    expected_keys_and_properties.each_with_object(initial_mapping) do |expected_key_and_properties, memo|
      expected_key, expected_properties = expected_key_and_properties
      if field_requires_mapping?(expected_properties)
        map_field(memo, expected_key, expected_properties, observed_keys)
      end
    end
  end

  def observed_keys
    return @state[:content][:raw].first.keys.map(&:to_s) if @state[:content] && @state[:content][:raw] && !@state[:content][:raw].empty?
    []
  end

  def expected_field?(field_properties)
    field_properties['required'] || field_properties['show_on_form']
  end

  def expected_keys_and_properties
    manifest_schema['properties'].each_pair.select do |_expected_key, field_properties|
      expected_field?(field_properties)
    end.map { |k, v| [k.to_s, v] }
  end

  def required_unmatched_fields
    required_schema_fields.reject { |f| matched_expected_fields.include?(f) }
  end

  def shown_unmatched_fields
    shown_schema_fields.reject { |f| matched_expected_fields.include?(f) }
  end

  def matched_expected_fields
    return [] unless state_access && state_access[:matched] && !state_access[:matched].empty?
    state_access[:matched].map { |m| m[:expected] }
  end

  def required_schema_fields
    manifest_schema['properties'].keys.select { |key| manifest_schema['properties'][key]['required'] == true }
  end

  def shown_schema_fields
    manifest_schema['properties'].keys.select { |key| manifest_schema['properties'][key]['show_on_form'] == true }
  end
end
