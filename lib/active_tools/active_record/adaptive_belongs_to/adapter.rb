module ActiveTools
  module ActiveRecord
    module AdaptiveBelongsTo
      class Adapter
        attr_reader :owner, :assoc_name, :options

        delegate :target, :reflection, :to => :association

        def initialize(owner, assoc_name, options = {})
          @owner = owner
          @assoc_name = assoc_name
          @options = options.with_indifferent_access
          @foreign_key = reflection.foreign_key
          @attr_map = @options[:attr_map]
          @remote_attributes = @attr_map.keys
          @init_proc = @options[:init_proc]
          @nullify_if = @options[:nullify_if]
          @update_if = @options[:update_if]
          @destroy_if = @options[:destroy_if]
          @uniq_by = Array(@options[:uniq_by]).map(&:to_s)
          @target_process = @options[:target_process]
          @touch = @options[:touch]
          association.load_target
        end

        def klass
          association.klass||reflection.class_name.constantize
        end

        def association
          owner.association(assoc_name)
        end

        def read(name)
          valid_attribute?(name)
          association.loaded? ? target.try(name) : association.reload.target.try(name)
        end

        def write(name, value)
          valid_attribute?(name)
          local_attribute = @attr_map[name]
          if value != read(name)
            owner.send(:attribute_will_change!, local_attribute)
            store_backup!
            create_template!
            target.send("#{name}=", value)
            @template.send("#{name}=", value)
            owner.send(:attributes_changed_by_setter).except!(local_attribute) if owner.changes[local_attribute].try(:last) == owner.changes[local_attribute].try(:first)
            if @backup.present? && same_records?(@backup, target, :attributes => @remote_attributes)
              restore_backup!
            end
          end
          value
        end

        def try_nullify
          if nullify_target?
            store_backup!
            self.target = nil
            true
          end
        end

        def try_commit
          try_commit_existed || try_restore_refreshed_backup
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

        def try_restore_refreshed_backup
          if updateable_backup?
            warn "Adaptive is going to update: <#{@backup.class.name}: #{@backup.class.primary_key}: #{@backup.send(@backup.class.primary_key)}>"
            @backup.attributes = template_attributes
            restore_backup!
            true
          end
        end

        def try_commit_existed
          if @template.present? && @uniq_by.any? && (existed = detect_existed) && !(@backup.present? && same_records?(@backup, existed, :attributes => @uniq_by))
            warn "Adaptive is fetching existed <#{existed.class.name}: #{existed.class.primary_key}: #{existed.send(existed.class.primary_key)}>"
            self.target = existed
            if updateable_backup?
              @backup.mark_for_destruction
            end
            true
          end
        end

        def try_destroy_backup
          if destroyable_backup?
            warn "Adaptive is destroying backed up: <#{@backup.class.name}: #{@backup.class.primary_key}: #{@backup.send(@backup.class.primary_key)}>"
            begin
              @backup.destroy
            rescue ::ActiveRecord::StaleObjectError
              @backup.reload
              try_destroy_backup
            rescue ::ActiveRecord::StatementInvalid
              @backup.reload
              try_destroy_backup
            end
          end
        end

        def try_destroy_target
          if destroyable_target?
            warn "Adaptive is destroying target: <#{target.class.name}: #{target.class.primary_key}: #{target.send(target.class.primary_key)}>"
            begin
              target.destroy
            rescue ::ActiveRecord::StaleObjectError
              target.reload
              try_destroy_target
            rescue ::ActiveRecord::StatementInvalid
              target.reload
              try_destroy_target
            end
          end
        end
        
        def target_process_do
          @target_process.try(:call, target, owner)
        end

        def update_target_if_changed!
          if target && target.changes.any?
            warn "Adaptive is updating: <#{target.class.name}: #{target.class.primary_key}: #{target.send(target.class.primary_key)}>"
            if @touch
              begin
                owner.touch
              rescue
              end
            end
            begin
              target.save
            rescue ::ActiveRecord::StaleObjectError
              update_target_if_changed!
            rescue ::ActiveRecord::StatementInvalid
              update_target_if_changed!
            end
          end
        end

        def clear!
          @template = nil
          @backup = nil
        end

        private

        def target_id
          association.send(:target_id)
        end

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
              where_values[attribute] = @template[attribute]
            end
          end
          klass.includes(outer_values).where(where_values).limit(1).first
        end

        def nullify_target?
          target.present? && @nullify_if.try(:call, target, owner) # .reload is NOT acceptable (flushes changes)
        end

        def updateable_backup?
          @backup.try(:persisted?) && @update_if.try(:call, @backup.reload, owner) # .reload is acceptable
        end

        def destroyable_backup?
          @backup.try(:persisted?) && (!@backup.destroyed?||@backup.marked_for_destruction?) && @destroy_if.try(:call, @backup.reload, owner) # .reload is acceptable
        end

        def destroyable_target?
          target.try(:persisted?) && (!target.destroyed?||target.marked_for_destruction?) && @destroy_if.try(:call, target.reload, owner) # .reload is acceptable
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
            true
          end
        end

        def store_backup!
          if target.try(:persisted?)
            @backup ||= target
          end
        end

        def same_records?(*args)
          options = args.extract_options!
          attributes = options[:attributes]
          result = true
          prev_object = args.shift
          args.each do |object|
            result = result && eval(attributes.map {|a| "object.send(:#{a}) == prev_object.send(:#{a})"}.join(" && "))
            prev_object = object
          end
          result
        end

        def valid_attribute?(name)
          raise(NameError, "Undefined remote attribute :#{name}!") unless @remote_attributes.include?(name.to_s)
        end

        def target=(record)
          if owner.persisted?
            if Rails.version >= "5.2.0"
              association.send(:replace_keys, record)
            elsif Rails.version >= "4.1.0"
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
