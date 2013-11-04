module ActiveTools
  module ActionPack
    module ActionDispatch
      module FlashStack
        # Doesn't work with Rails 4.0>
  
        extend ActiveSupport::Concern

        included do
          class_eval do
            def empty?
              @flashes.empty? && (@stack.nil? ? true : @stack.empty?)
            end
          end
        
          class Stack
            def initialize(flash)
              @flash = flash
              @stack = {}
            end

            def []=(k,v)
              @stack[k] = Array(v)
            end

            def [](k)
              @stack[k] ||= []
            end

            def method_missing(*args, &block)
              @stack.send(*args, &block)
            end

            def use
              @stack.dup.tap do
                @stack.clear
              end
            end
          end
        end

        def <<(*hashes)
          hashes.each do |hash|
            hash.each do |k,v|
              Array(v).each do |value|
                stack[k] << value
              end
            end
          end
        end

        def stack
          @stack ||= Stack.new(self)
        end
      end
    end
  end
  
  module OnLoadActiveRecord
    ::ActionDispatch::Flash::FlashHash.send(:include, ActionPack::ActionDispatch::FlashStack)
  end
  
end