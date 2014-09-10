module ActiveTools
  module CoreExtension
    module RuntimeCaching
      def acts_as_runtime_caching(*args)
        options = args.extract_options!
        args.each do |method|
          instance_eval <<-DELEGATORS
            def #{method}
              ::Thread.current[:#{method}]
            end

            def #{method}=(value)
              ::Thread.current[:#{method}] = (value)
            end
          DELEGATORS
        end
      end
      
      ::Class.send(:include, RuntimeCaching)
    end
  end
end