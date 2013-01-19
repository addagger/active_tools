require 'rails'
require 'active_tools/bundle'

module ActiveTools
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      ::ActiveSupport.on_load :active_record do
      end
      ::ActiveSupport.on_load :action_controller do
      end
      ::ActiveSupport.on_load :action_view do
      end
    end

  end
end