require 'active_tools/core_extension/deep_merge'
require 'active_tools/active_record/adaptive_belongs_to/adapter'
module ActiveTools
  module ActiveRecord
    module AdaptiveBelongsTo
      extend ::ActiveSupport::Concern
      
      included do
      end

      module ClassMethods
  
        def relation_options_under(*args)
          path = args.extract_options!
          local_attribute = args.first
          local_method = "#{local_attribute}_relation_options"

          define_singleton_method local_method do |instance = nil|
            outer_values = {}
            where_values = {}
            path.each do |assoc_name, remote_attributes|
              reflection = reflections[assoc_name]
              target = instance.try(reflection.name)
              outer_values[reflection.name] = {}
              Array(remote_attributes).each do |remote_attribute|
                remote_method = "#{remote_attribute}_relation_options"
                if reflection.klass.respond_to?(remote_method)
                  deeper = reflection.klass.send(remote_method, target)
                  outer_values[reflection.name].merge!(deeper[:outer_values])
                  where_values.merge!(deeper[:where_values])
                else
                  where_values[reflection.table_name] ||= {}.with_indifferent_access
                  where_values[reflection.table_name][remote_attribute] = target.try(remote_attribute)
                end
              end
            end
            {:outer_values => outer_values, :where_values => where_values}
          end
          
          class_eval do
            define_method local_method do
              self.class.send(local_method, self)
            end
          end
          
        end
        
        def adaptive_belongs_to(*args)
          options = args.extract_options!
          assoc_name = args.first
          unless reflection = reflections[assoc_name]
            raise(ArgumentError, ":#{assoc_name} method doesn't look like an association accessor!")
          end
          adapter_name = "#{assoc_name}_adaptive"
          config_name = "#{assoc_name}_adaptive_options"
          
          raise(TypeError, "Option :attributes must be a Hash. #{options[:attributes].class} passed!") unless options[:attributes].is_a?(Hash)
          attr_map = options.delete(:attributes).with_indifferent_access
       
          valid_with assoc_name, :attributes => attr_map
        
          class_attribute config_name
          self.send("#{config_name}=", options.merge(:remote_attributes => attr_map.keys))
          
          class_eval <<-EOV
            before_validation do
              #{adapter_name}.try_nullify
            end
          
            #{Rails.version >= "4.1.0" ? "before_validation" : "before_save"} do
              #{adapter_name}.try_commit
            end

            after_save do
              #{adapter_name}.try_destroy_backup
              #{adapter_name}.clear!
            end

            after_destroy do
              #{adapter_name}.try_destroy
            end
          
            def #{adapter_name}
              puts "dfasfsfsfs"
              ActiveTools::ActiveRecord::AdaptiveBelongsTo::Adapter.new(association(:#{assoc_name}), #{config_name})
            end
          EOV

          attr_map.each do |remote_attribute, local_attribute|
            relation_options_under(local_attribute, assoc_name => remote_attribute)
            class_eval do
              define_method local_attribute do
                send(adapter_name).read(remote_attribute)
              end
          
              define_method "#{local_attribute}=" do |value|
                send(adapter_name).write(remote_attribute, value)
              end
            end
          end
          
        end    
      end
    end
  end
  
  module OnLoadActiveRecord
    include ActiveRecord::AdaptiveBelongsTo
  end
  
end