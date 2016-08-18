require 'active_tools/misc/uniq_content'

module ActiveTools
  module Misc
    DEFAULT_JS_FLOW_KEY = :_script_flow
  end
  
  module OnLoadActionController
    # def _render_template(*args)
    #   rendering = super
    #   if lookup_context.rendered_format == :js
    #     rendering + uniq_content_storage.render_content(Misc::DEFAULT_JS_FLOW_KEY)
    #   else
    #     rendering
    #   end
    # end
  end
  
  module OnLoadActionView
    def script_flow!
      uniq_content_storage.render_content(Misc::DEFAULT_JS_FLOW_KEY)
    end
    
    def script(*args, &block)
      options = args.extract_options!
      content = args.first
      if content || block_given?
        if block_given?
          content = capture(&block)
        end
        if content
          case request.format
          when Mime[:js] then
            uniq_content_storage.append_content(content, Misc::DEFAULT_JS_FLOW_KEY)
            nil
          when Mime[:html] then
            volume = options.delete(:volume)
            unless uniq_content_storage.remembered?(content, volume)
              flow = uniq_content_storage.remember(content, volume)
              options[:javascript_tag] == false ? flow : javascript_tag(flow, options)
            end
          end
        end
      end
    end

    def script_for(identifier, *args, &block)
      options = args.extract_options!
      if block_given?
        content_for(identifier) do
          script(args, options.merge(:volume => identifier), &block)
        end
      else
        content_for(identifier, script(args, options.merge(:volume => identifier)).join("\n").html_safe)
      end
    end
  end
  
end