# frozen_string_literal: true

module DispatchSteps
  class FailStep
    def up
      raise 'This step fails'
    end

    def down; end
  end
end
