module ActiveTools
  module Misc
    module UniqContent
      class Storage    
        attr_reader :content

        delegate :any?, :empty?, :to => :content

        def initialize
          @content = ::ActiveSupport::OrderedHash.new {|h,k| h[k] = []}
          @hashes = ::ActiveSupport::OrderedHash.new {|h,k| h[k] = []}
        end

        # Called by _layout_for to read stored values.
        def get_content(key = nil)
          @content[key]
        end

        # Called by each renderer object to set the layout contents.
        def set_content(value, key = nil)
          @content[key] = Array(value)
        end

        # Called by content_for
        def append_content(value, key = nil)
          @content[key] |= Array(value)
        end
        alias_method :append_content!, :append_content

        def render_content(key = nil)
          @content[key].join("\n").html_safe
        end
        
        def remember(value, key = nil)
          unless remembered?(value, key)
            @hashes[key] << value.hash
            value
          end
        end
        
        def remembered?(value, key = nil)
          @hashes[key].include?(value.hash)
        end

      end
    end
  end
  
  module OnLoadActionController
    included do
      if respond_to?(:helper_method)
        helper_method :uniq_content_storage
      end
    end

    def uniq_content_storage
      @_uniq_content_storage ||= Misc::UniqContent::Storage.new
    end
  end
  
  module OnLoadActionView
    def uniq_content(*args, &block)
      options = args.extract_options!
      content = args.first
      if content || block_given?
        if block_given?
          content = capture(&block)
        end
        if content && !uniq_content_storage.remembered?(content, options[:volume])
          uniq_content_storage.remember(content, options[:volume])
        else
          nil
        end
      end
    end
  end
  
end