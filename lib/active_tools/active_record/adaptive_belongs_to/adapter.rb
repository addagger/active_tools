module ActiveTools
  module ActiveRecord
    module AdaptiveBelongsTo
      class Adapter
        attr_reader :association, :options

        delegate :target, :target_id, :klass, :owner, :reflection, :to => :association

        def initialize(association, options = {})
          @association = association
          @options = options.with_indifferent_access
          @foreign_key = reflection.foreign_key
          @remote_attributes = @options[:remote_attributes]
          @init_proc = @options[:init_proc]
          @update_if = @options[:update_if]
          @destroy_if = @options[:destroy_if]
          @uniq_by = Array(@options[:uniq_by]).map(&:to_s)
          @association.load_target
        end

        def read(name)
          valid_attribute?(name)
          target.send(name) if target
        end

        def write(name, value)
          valid_attribute?(name)
          if value != read(name)
            store_backup!
            create_template!
            target.send("#{name}=", value)
            if same_as_backup?
              restore_backup!
            end
          end
        end

        def try_commit
          try_commit_existed || try_update
        end

        def try_destroy
          try_destroy_backup
          try_destroy_target
        end

        def try_update
          if updateable_backup?
            begin
              @backup.update(attributes(@template, *@remote_attributes))
            rescue ::ActiveRecord::StaleObjectError
              @backup.reload
              try_update
            end
            self.target = @backup
          end
        end

        def try_commit_existed
          if @template.present? && @uniq_by.any? && existed = detect_existed
            self.target = existed
            try_destroy_updateable_backup
            true
          end 
        end

        def try_destroy_backup
          if destroyable_backup?
            begin
              @backup.destroy
            rescue ::ActiveRecord::StaleObjectError
              @backup.reload
              try_destroy_backup
            end
          end
        end

        def try_destroy_updateable_backup
          if updateable_backup?
            begin
              @backup.destroy
            rescue ::ActiveRecord::StaleObjectError
              @backup.reload
              try_destroy_updateable_backup
            end
          end
        end

        def try_destroy_target(force = false)
          if destroyable_target?
            begin
              target.destroy
            rescue ::ActiveRecord::StaleObjectError
              target.reload
              try_destroy_target
            end
          end
        end

        def clear!
          @template = nil
          @backup = nil
        end

        private

        def detect_existed
          outer_values = {}
          where_values = {}
          @uniq_by.each do |attribute|
            relation_options_call = "#{attribute}_relation_options"
            if klass.respond_to?(relation_options_call)
              values = @template.send(relation_options_call)
              outer_values.merge!(values[:outer_values])
              where_values.merge!(values[:where_values])
            else
              where_values[attribute] = @template.send(attribute)
            end
          end
          klass.includes(outer_values).where(where_values).limit(1).first
        end

        def updateable_backup?
          @backup.present? && @update_if.try(:call, @backup)
        end

        def destroyable_backup?
          @backup.present? && !@backup.destroyed? && @destroy_if.try(:call, @backup)
        end

        def destroyable_target?
          target.try(:persisted?) && !target.destroyed? && @destroy_if.try(:call, target)
        end
        
        def attributes(object, *attrs)
          Hash[attrs.map {|a| [a, object.send(a)]}]
        end

        def create_template!
          if target.nil? || @template.nil? 
            self.target = template
          end
        end

        def restore_backup!
          if @backup
            self.target = @backup
            @backup = nil
          end
        end
        
        def store_backup!
          if target.try(:persisted?)
            @backup ||= target
          end
        end

        def same_as_backup?
          @backup.present? && eval(@remote_attributes.map {|a| "@backup.send(:#{a}) == target.send(:#{a})"}.join(" && "))
        end

        def valid_attribute?(name)
          raise(NameError, "Undefined remote attribute :#{name}!") unless @remote_attributes.include?(name.to_s)
        end

        def target=(record)
          if owner.persisted?
            association.send(:replace_keys, record)
            association.set_inverse_instance(record)
            association.instance_variable_set(:@updated, true) if record != @backup
            association.target = record
          else
            association.replace(record)
          end
        end

        def template
          @template ||=
          if target.try(:persisted?)
            klass.new(attributes(target, *@remote_attributes))
          elsif target.nil?
            klass.new
          elsif target.try(:new_record?)
            target.dup
          end
          @template.tap do |t|
            @init_proc.try(:call, t)
          end
        end 
      end

    end
  end
  
end