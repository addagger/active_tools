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
              reflection = reflections.with_indifferent_access[assoc_name]
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
          unless reflection = reflections.with_indifferent_access[assoc_name]
            raise(ArgumentError, ":#{assoc_name} method doesn't look like an association accessor!")
          end
          adapter_name = "#{assoc_name}_adaptive"

          raise(TypeError, "Option :attributes must be a Hash. #{options[:attributes].class} passed!") unless options[:attributes].is_a?(Hash)
          attr_map = HashWithIndifferentAccess.new(options.delete(:attributes))
          valid_options = Hash(options.delete(:valid_with)).symbolize_keys
          valid_with assoc_name, valid_options.merge(:attributes => attr_map) #, :fit => true

          class_attribute :adaptive_options unless defined?(adaptive_options)
          self.adaptive_options ||= {}
          self.adaptive_options[assoc_name.to_sym] = options.merge(:attr_map => attr_map)

          class_eval <<-EOV
            before_validation do
              #{adapter_name}.try_nullify||#{adapter_name}.try_commit
              #{adapter_name}.target_process_do
            end

            before_save do
              #{adapter_name}.update_target_if_changed!
            end

            after_save do
              #{adapter_name}.try_destroy_backup
              #{adapter_name}.clear!
            end

            after_destroy do
              #{adapter_name}.try_destroy
            end

            def #{adapter_name}
              @#{adapter_name} ||= ActiveTools::ActiveRecord::AdaptiveBelongsTo::Adapter.new(self, :#{assoc_name}, adaptive_options[:#{assoc_name}])
            end
          EOV

          attr_map.each do |remote_attribute, local_attribute|
            if Rails.version >= "5.0"
              attribute local_attribute, reflection.klass.attribute_types[remote_attribute].dup
              after_initialize do
                self[local_attribute] = send(local_attribute)
              end
            end
            relation_options_under(local_attribute, assoc_name => remote_attribute)
            class_eval do
              define_method local_attribute do
                send(adapter_name).read(remote_attribute)
              end
              define_method "#{local_attribute}=" do |value|
                if Rails.version >= "5.0"
                  super send(adapter_name).write(remote_attribute, value)
                else
                  send(adapter_name).write(remote_attribute, value)
                end
              end
            end
          end

        end
      end

      # def reload(*args)
      #   super.tap do |record|
      #     adaptive_options.keys.each do |assoc_name|
      #       puts assoc_name
      #       adapter_name = "#{assoc_name}_adaptive"
      #       eval("@#{adapter_name}.try(:replace_association, association(:#{assoc_name}))")
      #     end
      #   end
      # end

    end
  end

  module OnLoadActiveRecord
    include ActiveRecord::AdaptiveBelongsTo
  end

end
