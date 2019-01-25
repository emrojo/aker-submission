# frozen_string_literal: true

# Defines a shared example which takes the Lint Test::Unit tests and creates RSpec examples
# to ensure your model is complaint with the ActiveModelAPI.

shared_examples_for 'ActiveModel' do
  include ActiveModel::Lint::Tests

  ActiveModel::Lint::Tests.public_instance_methods.map(&:to_s).grep(/^test/).each do |m|
    example m.tr('_', ' ') do
      send m
    end
  end

  def model
    subject
  end
end
