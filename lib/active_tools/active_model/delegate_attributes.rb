module ActiveTools
  module ActiveModel
    module DelegateAttributes
      extend ::ActiveSupport::Concern
      
      included do
        class FakeErrors < ::ActiveModel::Errors
          private
          def normalize_message(attribute, message, options)
            message ||= :invalid
          end
        end
        
      end
      
      module ClassMethods
        def delegate_attributes(*args)
          options = args.extract_options!
          errors_option = options.delete(:errors)
          writer_option = options.delete(:writer)

          writer_regexp = /=\z/
          readers = args.select {|a| a.to_s !=~ writer_regexp}
          writers = args.select {|a| a.to_s =~ writer_regexp}
          if writer_option == true
            writers += readers.map {|a| "#{a}="}
          end

          class_eval do
            delegate *(readers + writers), options.dup
          end          

          unless errors_option == false
            class_eval <<-EOV
              validate do
                object = #{options[:to]}
                #{"object.instance_variable_set(:@errors, FakeErrors.new(object))" if errors_option.to_s == "fit"}
                if !object.valid?
                  object.errors.messages.each do |attribute, suberrors|
                    if attribute.to_s.in? %w{#{readers.join(" ")}}
                      suberrors.each do |suberror|
                        errors.add(attribute, suberror)
                      end
                    end
                  end
                end
              end
            EOV
          end
        end
      end
      
      
    end
  end
  
  module OnLoadActiveRecord
    ::ActiveModel::Validations.send(:include, ActiveModel::DelegateAttributes)    
  end
  
end