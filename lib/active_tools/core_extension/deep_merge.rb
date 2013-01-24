module ActiveTools
  module CoreExtension
    
    module DeepMerge
      
      module HashExtension
        # Return the merged Hash with another +hash+, where the possible child hashes are also merged.
        #
        # === Example:
        # 
        #   h1 = {:breakfast => {:eggs => 2, :bread => 1}, :lunch => {:steak => 1, :salad => 1}}
        #   h2 = {:breakfast => {:coffee => :espresso, :juice => 1}, :lunch => {:tea => 2}, :dinner => :none}
        #   h1.deep_merge(h2)
        #   #=> {:breakfast=>{:eggs=>2, :bread=>1, :coffee=>:espresso, :juice=>1}, :lunch=>{:steak=>1, :salad=>1, :tea=>2}, :dinner=>:none}
        def deep_merge(other_hash = {})
          dup.tap do |hash|
            other_hash.each do |key, value|
              if !hash.has_key?(key) || !hash[key].is_a?(Hash)
                hash[key] = value
              elsif hash[key].is_a?(Hash) && value.is_a?(Hash)
                hash[key].deep_merge!(value)
              end
            end
          end
        end

        # .nested_merge replaces the source hash.
        def deep_merge!(other_hash = {})
          replace(deep_merge(other_hash))
        end
      end
      
      ::Hash.send(:include, HashExtension)
      
    end
  end
end