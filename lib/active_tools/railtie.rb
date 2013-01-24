require 'rails'
require 'active_tools/bundle'

module ActiveTools
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      ::ActiveSupport.on_load :active_record do
        include OnLoadActiveRecord
      end
      ::ActiveSupport.on_load :action_controller do
        include OnLoadActionController
      end
      ::ActiveSupport.on_load :action_view do
        include OnLoadActionView
      end
    end

  end
end