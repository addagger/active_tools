require 'active_tools/core_extension/deep_copy'
require 'active_tools/core_extension/deep_merge'
require 'active_tools/core_extension/hashup'
require 'active_tools/core_extension/merge_hashup'

module ActiveTools
  module CoreExtension

    module HashExtension
      include DeepCopy::Hash
      include DeepMerge::Hash
      include MergeHashup::Hash
    end

    module ArrayExtension
      include DeepCopy::Array
      include Hashup::Array
    end
    
    module SetExtension
      include DeepCopy::Set
    end

    ::Hash.send(:include, HashExtension)
    ::Array.send(:include, ArrayExtension)
    ::Set.send(:include, SetExtension)

  end
  
end
