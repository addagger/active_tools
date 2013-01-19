# dependent on deep_merge and deep_copy

module ActiveTools
  module CoreExtension
    
    module MergeHashup
      module Hash
        # Merge hashup sequence.
        #
        # === Example:
        #
        #   params = {"controller"=>"comments", "action"=>"show", "id"=>34, "article_id"=>3, "page"=>{"article"=>2}}
        #   
        #   params.merge_hashup(:page, :article, 34)
        #   # => {:controller => "comments", :action => "show", :id => 34, :article_id => 3, :page => {:article => 2, :comment => 34}}
        #
        def merge_hashup(*args)
          deep_merge(args.hashup)
        end
        
        def merge_hashup!(*args)
          deep_merge!(args.hashup)
        end
        
      end
    end
  end
end