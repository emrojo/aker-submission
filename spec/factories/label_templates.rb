# frozen_string_literal: true

FactoryBot.define do
  factory :label_template do
    name { 'template' }
    external_id { 16 }
    template_type { 'plate' }
  end
end
