module ActiveTools
  module ActiveModel
    module DelegateAttributes
      extend ::ActiveSupport::Concern
      
      module ClassMethods
        def delegate_attributes(*args)
          options = args.extract_options!
          errors_option = options.delete(:errors)
          writer_option = options.delete(:writer)
          prefix_option = options.delete(:prefix)

          writer_regexp = /=\z/
          readers = args.select {|a| a.to_s !=~ writer_regexp}
          writers = args.select {|a| a.to_s =~ writer_regexp}
          if writer_option == true
            writers |= readers.map {|a| "#{a}="}
          end

          class_eval do
            delegate *(readers + writers), options.dup
            unless errors_option == false
              valid_with options[:to], :attributes => Hash[readers.map {|a| [a, a]}], :fit => errors_option.to_s == "fit", :prefix => prefix_option
            end
          end          
        end
      end
      
      
    end

    ::ActiveModel::Validations.send(:include, ActiveModel::DelegateAttributes)    

  end
  
  module OnLoadActiveRecord
    #::ActiveRecord::Base.send(:include, ActiveModel::DelegateAttributes)
  end
  
end