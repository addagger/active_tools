require 'active_tools/action_pack/action_controller/path_helper/complex_helpers'

module ActiveTools
  module ActionPack
    module ActionController
      module PathHelper
        class HttpReferer
          attr_reader :url, :recognized
          include ComplexHelpers
          
          delegate :[], :to => :recognized
          
          def initialize(request, environment = {})
            @url = request.env['HTTP_REFERER']
            @recognized = begin
              @url.present? ? Rails.application.routes.recognize_path(@url, environment) : {}
            rescue ::ActionController::RoutingError
              {}
            end
            @recognized.freeze
          end

          def current_controller
            recognized[:controller]
          end

          def current_action
            recognized[:action]
          end
          
          def to_s
            @url
          end
        end
      end
    end
  end

end