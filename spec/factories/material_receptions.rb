# frozen_string_literal: true

FactoryBot.define do
  factory :material_reception do
    association :labware, factory: :dispatched_labware
  end
end
