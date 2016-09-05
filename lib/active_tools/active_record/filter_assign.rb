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
              case options[:to]
              when Proc then
                super(options[:to].call(value))
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