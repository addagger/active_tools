require "active_tools/version"

module ActiveTools
  def self.load!
    require 'active_tools/engine'
    require 'active_tools/railtie'
  end
end

ActiveTools.load!