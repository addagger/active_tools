require 'active_tools/misc/uniq_content'

module ActiveTools
  module ActionPack
    module ActionView
      module UniqContentFor
        
      end
    end
  end
  
  module OnLoadActionView
    
    def uniq_content_for(name, content = nil, options = {}, &block)
      if content || block_given?
        if block_given?
          options = content if content
          content = capture(&block)
        end
        if content && !uniq_content_storage.remembered?(content, name)
          content_for(name, uniq_content_storage.remember(content, name), options)
          nil
        end
      end
    end
    
  end
  
end