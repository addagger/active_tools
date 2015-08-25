module ActiveTools
  module ActionPack
    module ActionView
      module TagAttributes
        class Collect
          def initialize(hash = nil)
            @hash = HashWithIndifferentAccess.new {|h,k| h[k] = Array.new}
            merge(hash) if hash
          end

          def merge(hash = {})
            type_valid(hash).each {|key, value| self[key] = value}
            self
          end

          def to_s
            stringify_values.map {|k,v| "#{k}=\"#{v}\"" unless v.blank?}.compact.join(" ").html_safe
          end

          def [](key)
            @hash[key]
          end

          def []=(key, value)
            @hash[key] += Array[value]
          end

          def stringify_values
            Hash[@hash.map {|k,v| [k, v.join(" ")]}]
          end

          def hash
            Hash[@hash.map {|k,v| [k.to_sym, v]}]
          end

          private

          def type_valid(object = nil)
            raise(TypeError, "Hash or nil expected, #{object.class.name} passed.") unless object.is_a?(Hash) || object.nil?
            object||{}
          end

        end
      end
    end
  end
  
  module OnLoadActionView
    
    def tag_attributes(hash = {})
      ActionPack::ActionView::TagAttributes::Collect.new(hash)
    end
    
  end
  
end