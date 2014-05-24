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
          @nullify_if = @options[:nullify_if]
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
        
        def replace_association(association)
          @association = association
        end
        
        def try_nullify
          if nullify?    
            store_backup!
            self.target = nil
          end
        end

        def try_commit
          try_commit_existed || try_update
        end

        def try_destroy          
          try_destroy_backup
          try_destroy_target
        end

        def template_attributes
          attributes(@template, *@remote_attributes)
        end
        
        def target_attributes
          attributes(target, *@remote_attributes)
        end

        def try_update
          if updateable_backup?
            begin
              @backup.update(template_attributes)
            rescue ::ActiveRecord::StaleObjectError
              @backup.reload
              try_update
            end
            self.target = @backup
          end
        end

        def try_commit_existed
          if @template.present? && @uniq_by.any? && (existed = detect_existed)
            self.target = existed
            if updateable_backup?
              @backup.mark_for_destruction
            end
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

        def try_destroy_target
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
              outer_values.deep_merge!(values[:outer_values])
              where_values.deep_merge!(values[:where_values])
            else
              where_values[attribute] = @template.send(attribute)
            end
          end
          klass.includes(outer_values).where(where_values).limit(1).first
        end

        def nullify?
          target.present? && @nullify_if.try(:call, (target.persisted? ? target.reload : target), owner)
        end

        def updateable_backup?
          @backup.try(:persisted?) && @update_if.try(:call, @backup.reload, owner)
        end

        def destroyable_backup?
          @backup.try(:persisted?) && (!@backup.destroyed?||@backup.marked_for_destruction?) && @destroy_if.try(:call, @backup.reload, owner)
        end

        def destroyable_target?
          target.try(:persisted?) && (!target.destroyed?||target.marked_for_destruction?) && @destroy_if.try(:call, target.reload, owner)
        end
        
        def attributes(object, *attrs)
          array = attrs.map do |a|
            begin
              [a, object.send(a)]
            rescue NoMethodError
              nil
            end
          end.compact
          Hash[array]
        end

        def create_template!
          if target.nil? || @template.nil? 
            self.target = template
          end
        end

        def restore_backup!
          if @backup
            if @backup.marked_for_destruction?
              @backup.instance_variable_set(:@marked_for_destruction, false)
            end
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
            if Rails.version >= "4.1.0"
              if record
                association.send(:replace_keys, record)
              else
                association.send(:remove_keys)
              end
            else
              association.send(:replace_keys, record)
            end
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
            klass.new(target_attributes)
          elsif target.nil?
            klass.new
          elsif target.try(:new_record?)
            target.dup
          end
          @template.tap do |t|
            @init_proc.try(:call, t, owner)
          end
        end 
      end

    end
  end
  
end