module ActiveTools
  module CoreExtension
    
    module MethodDigger
      module ObjectExtension
        def method_digger(tree, &block)
          tree.stringify_keys!
          tree.each do |method, value|
            if method.last == "*"
              method = method[0..-2]
              cycle_call(method) do |nested|
                yield self, method, nested, value
                if value.is_a?(Hash) && !nested.nil?
                  nested.method_digger(value, &block)
                end
              end
            else
              response = try(method)
              yield self, method, response, value
              if value.is_a?(Hash) && !response.nil?
                response.method_digger(value, &block)
              end
            end
          end
        end
        
        def cycle_call(method, &block)
          object = self
          export = []
          while object = object.try(method)
            yield object if block_given?
            export << object
          end
          export
        end
        
      end

      ::Object.send(:include, ObjectExtension)
    end
  end
end