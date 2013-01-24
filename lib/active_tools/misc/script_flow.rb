module ActiveTools
  module Misc
    module ScriptFlow
      class Map
        attr_reader :content

        delegate :any?, :empty?, :to => :content

        def initialize
          @content = ::ActiveSupport::OrderedHash.new { |h,k| h[k] = ::ActiveSupport::SafeBuffer.new }
        end

        # Called by _layout_for to read stored values.
        def get(key)
          @content[key]
        end

        # Called by each renderer object to set the layout contents.
        def set(key, value)
          @content[key] = value
        end

        # Called by content_for
        def append(key, value)
          @content[key] << value
        end
        alias_method :append!, :append

        def add_script(script)
          set(script.hash, script)
        end

        def render
          @content.values.join("\n").html_safe
        end

      end
    end
  end
  
  module OnLoadActionController
    included do
      helper_method :script_flow
    end

    def script_flow
      @script_flow ||= Misc::ScriptFlow::Map.new
    end

    def _render_template(options)
      if lookup_context.rendered_format == :js
         super + script_flow.render
      else
        super
      end
    end
  end
  
  module OnLoadActionView
    def script(content = nil, &block)
      if content || block_given?
        if block_given?
          content = capture(&block)
        end
        if content
           case request.format
           when Mime::JS then
             script_flow.add_script(content)
             nil
           when Mime::HTML then
             javascript_tag(content)
           end
        end
      end
    end

    def script_for(identifier, content = nil, &block)
      content_for(identifier, script(content, &block))
    end
  end
  
end