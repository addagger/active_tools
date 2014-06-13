module ActiveTools
  module ActionPack
    module ActionController
      module PathHelper
        module ComplexHelpers
          def path?(controller, action = nil)
            controller?(controller) && action?(action)
          end

          def action?(action)
            actions = case action
            when Array then action.map {|c| c.to_s}
            when String, Symbol then Array.wrap(action.to_s)
            else nil
            end
            actions.blank? ? true : current_action.in?(actions)
          end

          def controller?(controller)
            controllers = case controller
            when Array then controller.map {|c| c.to_s}
            when String, Symbol then Array.wrap(controller.to_s)
            else nil
            end
            controllers.blank? ? true : current_controller.in?(controllers)
          end
        end
      end
    end
  end

end