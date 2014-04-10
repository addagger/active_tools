require 'active_tools/misc/uniq_content'

module ActiveTools
  module Misc
    DEFAULT_JS_FLOW_KEY = :_script_flow
  end
  
  module OnLoadActionController
    def _render_template(options)
      if lookup_context.rendered_format == :js
         super + uniq_content_storage.render_content(Misc::DEFAULT_JS_FLOW_KEY)
      else
        super
      end
    end
  end
  
  module OnLoadActionView
    def script(*args, &block)
      options = args.extract_options!
      content = args.first
      if content || block_given?
        if block_given?
          content = capture(&block)
        end
        if content
          case request.format
          when Mime::JS then
            uniq_content_storage.append_content(content, Misc::DEFAULT_JS_FLOW_KEY)
            nil
          when Mime::HTML then
            unless uniq_content_storage.remembered?(content, options[:volume])
              flow = uniq_content_storage.remember(content, options[:volume])
              options[:javascript_tag] == false ? flow : javascript_tag(flow, options)
            end
          end
        end
      end
    end

    def script_for(identifier, *args, &block)
      options = args.extract_options!
      content_for(identifier) do
        script(args, options.merge(:volume => identifier), &block)
      end
    end
  end
  
end