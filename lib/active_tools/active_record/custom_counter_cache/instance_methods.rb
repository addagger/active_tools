module ActiveTools
  module ActiveRecord
    module CustomCounterCache
      module InstanceMethods
        def custom_counter_cache_after_create(assoc_name, reflection, assoc_mapping)
          if record = send(assoc_name)
            ActiveRecord::CustomCounterCache.digger(self, record, assoc_mapping) do |parent, cache_column, value|
              parent.class.update_counters(parent.id, cache_column => value)
            end
            @_after_create_custom_counter_called = true
          end
        end

        def custom_counter_cache_before_destroy(assoc_name, reflection, assoc_mapping)
          unless destroyed_by_association && (destroyed_by_association.foreign_key.to_sym == reflection.foreign_key.to_sym)
            if (record = send(assoc_name)) && !self.destroyed?
              ActiveRecord::CustomCounterCache.digger(self, record, assoc_mapping) do |parent, cache_column, value|
                parent.class.update_counters(parent.id, cache_column => -value)
              end
            end
          end
        end

        def custom_counter_cache_after_update(assoc_name, reflection, assoc_mapping)
          record_changed =
          if reflection.polymorphic?
            send(:attribute_changed?, reflection.foreign_type)||send(:attribute_changed?, reflection.foreign_key)
          else
            send(:attribute_changed?, reflection.foreign_key) && defined?(reflection.klass.to_s.camelize)
          end
          
          if (@_after_create_custom_counter_called ||= false)
            @_after_create_custom_counter_called = false
          elsif !new_record? && record_changed
            model           = reflection.polymorphic? ? attribute(reflection.foreign_type).try(:constantize) : reflection.klass
            model_was       = reflection.polymorphic? ? attribute_was(reflection.foreign_type).try(:constantize) : reflection.klass
            foreign_key     = attribute(reflection.foreign_key)
            foreign_key_was = attribute_was(reflection.foreign_key)

            if foreign_key && model.respond_to?(:increment_counter) && to_increment = model.find_by_id(foreign_key)
              ActiveRecord::CustomCounterCache.digger(self, to_increment, assoc_mapping) do |parent, cache_column, value|
                parent.class.update_counters(parent.id, cache_column => value)
              end
            end
            if foreign_key_was && model_was.respond_to?(:decrement_counter) && to_decrement = model_was.find_by_id(foreign_key_was)
              ActiveRecord::CustomCounterCache.digger(self, to_decrement, assoc_mapping) do |parent, cache_column, value|
                parent.class.update_counters(parent.id, cache_column => -value)
              end
            end
          end
        end
      end
    
    end
  end
end
