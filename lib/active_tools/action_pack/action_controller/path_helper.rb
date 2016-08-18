require 'active_tools/action_pack/action_controller/path_helper/complex_helpers'
require 'active_tools/action_pack/action_controller/path_helper/http_referer'

module ActiveTools
  module ActionPack
    module ActionController
      module PathHelper
        extend ::ActiveSupport::Concern
        
        included do
          if respond_to?(:helper_method)
            include ComplexHelpers
            helper_method :path?, :action?, :controller?, :current_action, :current_controller, :http_referer
          end
        end
        
        def current_action
          request.path_parameters[:action]
        end

        def current_controller
          request.path_parameters[:controller]
        end
        
        def http_referer(environment = {})
          @http_referer ||= HttpReferer.new(request, environment)
        end
        
      end
    end
  end
  
  module OnLoadActionController
    include ActionPack::ActionController::PathHelper
  end
end