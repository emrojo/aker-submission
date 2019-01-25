# frozen_string_literal: true

module Projects
  class Application
    VERSION = File.exist?('config/version') ? File.read('config/version') : ''
  end
end
