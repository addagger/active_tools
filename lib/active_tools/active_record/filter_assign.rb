module ActiveTools
  module ActiveRecord
    module FilterAssign
      extend ::ActiveSupport::Concern
      
      included do
      end
      
      module ClassMethods
        def filter_assign(*args)
          options = args.extract_options!
          args.each do |attribute|
            define_method "#{attribute}=" do |value|
              if (options[:if].nil? || (options[:if].is_a?(Proc) && options[:if].call(value) == true)) && (options[:unless].nil? || (options[:unless].is_a?(Proc) && options[:unless].call(value) == false))
                if options.has_key?(:force_value)
                  super(options[:force_value])
                end
              else
                super(value)
              end
            end
          end
        end
      end
      
    end
  end
  
  module OnLoadActiveRecord
    include ActiveRecord::FilterAssign
  end
  
end