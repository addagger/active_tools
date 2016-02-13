require 'active_tools/active_model/valid_with/fake_errors'
module ActiveTools
  module ActiveModel
    module ValidWith
      extend ::ActiveSupport::Concern
      
      module ClassMethods
        def valid_with(*args)
          options = args.extract_options!
          object_name = args.first
          passed_attr_map = options.delete(:attributes)||{}
          prefix = options.delete(:prefix)
          fit = options.delete(:fit)||false
          attr_map_name = :"_valid_with_#{object_name}"
          unless respond_to?(attr_map_name)
            class_attribute attr_map_name 
            self.send("#{attr_map_name}=", passed_attr_map.with_indifferent_access)
          else
            self.send(attr_map_name).merge!(passed_attr_map)
          end

          validate(*[options]) do
            if object = send(object_name)
              if fit
                object.instance_variable_set(:@errors, ActiveTools::ActiveModel::ValidWith::FakeErrors.new(object))
              end
              if !object.valid?
                object.errors.messages.each do |attribute, suberrors|
                  local_attribute = send(attr_map_name)[attribute]||attribute
                  suberrors.each do |suberror|
                    errors.add([prefix.to_s, local_attribute].select(&:present?).join("_"), suberror)
                  end
                end
              end
            end
          end
        end
      end
      
      
    end

    ::ActiveModel::Validations.send(:include, ActiveModel::ValidWith)    

  end
  
  module OnLoadActiveRecord
  end
  
end