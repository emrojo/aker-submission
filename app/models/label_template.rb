# frozen_string_literal: true

class LabelTemplate < ApplicationRecord
  validates :name, :external_id, presence: true
  validates :name, :external_id, uniqueness: true
end
