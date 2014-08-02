module ActiveTools
  module CoreExtension
    module RuntimeCaching
      def acts_as_runtime_caching(*args)
        options = args.extract_options!
        accessors = args
        thread_key = options[:thread_key]||::SecureRandom.urlsafe_base64(nil, false).to_sym
        send(:include, ::Singleton)
        container = Class.new
        container.send(:include, ::ActiveSupport::Configurable)
        container.instance_eval do
          config_accessor *accessors
        end
        define_method :config do
          ::Thread.current[thread_key] ||= container.new
        end
        define_method :"config=" do |value|
          ::Thread.current[thread_key] = value
        end
        accessors.each do |method|
          instance_eval <<-DELEGATORS
            def #{method}
              instance.config.#{method}
            end

            def #{method}=(value)
              instance.config.#{method} = (value)
            end
          DELEGATORS
        end
      end
      
      ::Class.send(:include, RuntimeCaching)
    end
  end
end