module ActiveTools
  module ActionPack
    module ActionController
      module PathHelper
        extend ::ActiveSupport::Concern
        
        included do
          helper_method :path?, :action?, :controller?, :current_action, :current_controller
        end
        
        def path?(controller, action = nil)
          controller?(controller) && action?(action)
        end

        def action?(action)
          actions = case action
          when Array then action.collect {|c| c.to_s}
          when String, Symbol then Array.wrap(action.to_s)
          else nil
          end
          actions.blank? ? true : current_action.in?(actions)
        end

        def controller?(controller)
          controllers = case controller
          when Array then controller.collect {|c| c.to_s}
          when String, Symbol then Array.wrap(controller.to_s)
          else nil
          end
          controllers.blank? ? true : current_controller.in?(controllers)
        end

        def current_action
          request.path_parameters[:action]
        end

        def current_controller
          request.path_parameters[:controller]
        end
      end
    end
  end
  
  module OnLoadActionController
    include ActionPack::ActionController::PathHelper
  end
end