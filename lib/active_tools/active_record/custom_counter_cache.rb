require 'active_tools/active_record/custom_counter_cache/instance_methods'

module ActiveTools
  module ActiveRecord
    module CustomCounterCache
      extend ::ActiveSupport::Concern
      
      included do
      end
      
      module ClassMethods
        def custom_counter_cache_for(*args)
          mapping = args.extract_options!
          
          class_attribute :custom_counter_cache_options unless defined?(custom_counter_cache_options)
          self.custom_counter_cache_options ||= {}
          self.custom_counter_cache_options[:mapping] = mapping.with_indifferent_access
          
          mapping.each do |assoc_name, value|
            assoc_name = assoc_name.to_s
            if assoc_name.last == "*"
              if value.is_a?(Hash)
                assoc_mapping = value.merge(assoc_name => value)
              end
              assoc_name = assoc_name[0..-2]
            else
              assoc_mapping = value
            end
            reflection = reflections[assoc_name.to_s]
          
            unless method_defined? :custom_counter_cache_after_create
              include ActiveRecord::CustomCounterCache::InstanceMethods
            end
          
            after_create lambda { |record|
              record.custom_counter_cache_after_create(assoc_name, reflection, assoc_mapping)
            }

            before_destroy lambda { |record|
              record.custom_counter_cache_before_destroy(assoc_name, reflection, assoc_mapping)
            }

            after_update lambda { |record|
              record.custom_counter_cache_after_update(assoc_name, reflection, assoc_mapping)
            }
          end
        end
      end

      def self.digger(owner, object, mapping)
        object.method_digger(mapping) do |object, key, response, value|
          if response && !response.is_a?(::ActiveRecord::Base)
            count = case value
            when String, Symbol then owner.send(value)
            when Integer then value
            end
            yield object, key, count          
          end
        end
      end
      
    end
  end
  
  module OnLoadActiveRecord
    include ActiveRecord::CustomCounterCache
  end
  
end