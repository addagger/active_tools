require "active_tools/version"

module ActiveTools
  def self.load!
    require 'active_tools/engine'
    require 'active_tools/railtie'
    require 'active_tools/core_extension'

  end
end

ActiveTools.load!