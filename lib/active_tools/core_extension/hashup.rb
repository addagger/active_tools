module ActiveTools
  module CoreExtension
    
    module Hashup
      module ArrayExtension
        # Return a nested Hash object from Array's elements sequence, where elements used as names of +hash+ keys.
        # The last element of array would be the last nested value.
        #
        # === Example:
        #   
        #   [:vehicle, :car, :ford, :mustang, "2 please"].hashup
        #
        #   #=> {:vehicle=>{:car=>{:ford=>{:mustang=>"2 please"}}}}
        def hashup
          raise(Exception, "At least 2 elements needed!") if size < 2
          value = delete_at(-1)
          {}.tap do |hash|
            index = 0
            while index < size
              hash = hash[at(index)] = (index + 1 == size) ? value : {}
              index += 1
            end
          end
        end
      end
      ::Array.send(:include, ArrayExtension)
    end
  end
end