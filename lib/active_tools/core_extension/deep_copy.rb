module ActiveTools
  module CoreExtension
    
    module DeepCopy
      # Return the 'deep' brand new copy of Hash, Array or Set. All nested hashes/arrays/sets rebuilded at the same way.
      
      module HashExtension
        def deep_copy(&block)
          self.class.new.tap do |new_hash|
            each do |k, v|
              new_hash[k] = case v
              when Hash, Array, Set then v.deep_copy(&block)
              else
                block_given? ? yield(v) : v.dup rescue v
              end
            end
          end
        end
      end

      module ArrayExtension
        def deep_copy(&block)
          self.class.new.tap do |new_array|
            each do |v|
              new_array << case v
              when Hash, Array, Set then v.deep_copy(&block)
              else
                block_given? ? yield(v) : v.dup rescue v
              end
            end
          end
        end
      end

      module SetExtension
        def deep_copy(&block)
          self.class.new.tap do |new_set|
            each do |v|
              new_set << case v
              when Hash, Array, Set then v.deep_copy(&block)
              else
                block_given? ? yield(v) : v.dup rescue v
              end
            end
          end
        end
      end
      
      ::Hash.send(:include, HashExtension)
      ::Array.send(:include, ArrayExtension)
      ::Set.send(:include, SetExtension)
      
    end
  end
end