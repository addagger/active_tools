module ActiveTools
  module ActiveRecord
    module WithPermalink
      extend ::ActiveSupport::Concern

      module ClassMethods
        def with_permalink(*args)
          options = args.extract_options!
          unless (column_name = args.first.to_sym) || options[:from].present?
            raise "WithPermalink: column_name and/or options[:from] expected!"
          end

          options[:uniq] ||= true

          cattr_accessor :with_permalink_options unless defined?(with_permalink_options)
          self.with_permalink_options ||= {}
          self.with_permalink_options[column_name] = options
          
          uniqueness_options = options[:scope] ? {:scope => Array(options[:scope])} : {}
          
          validates_presence_of column_name
          validates_uniqueness_of column_name, uniqueness_options
          validates_length_of column_name, :maximum => 255
          
          before_validation do
            self.with_permalink_options.each do |column_name, options|
              eval <<-EOV
                source = @_#{column_name}_demanded
              EOV
              source ||= case options[:from]
              when String, Symbol then send(options[:from])
              when Proc then options[:from].call(self)
              end
              if options[:uniq]
                self.send("#{column_name}=", generate_permalink(column_name, source, options))
              else
                self.send("#{column_name}=", source)
              end
            end
          end

          after_save do
            instance_variable_set(:"@_#{column_name}_demanded", nil)
          end

          class_eval <<-EOV
            def #{column_name}=(value)
              @_#{column_name}_demanded = value if value.present?
              super(value)
            end

            def to_param
              changes["#{column_name}"].try(:first)||#{column_name}
            end        
          EOV

        end
      end

      def generate_permalink(column_name, permalink, options = {})
        tester, correction = permalink, 0
        while exists_permalink?(column_name, tester, options)
          correction += 1
          tester = [permalink, correction].select(&:present?).join("-")
        end
        tester
      end

      def exists_permalink?(column_name, permalink, options = {})
        sql_clause, values = [], []
        sql_clause << "#{column_name} = ?"
        values << permalink
        if options[:scope]
          Array(options[:scope]).each do |field|
            if value = send(field)
              sql_clause << "#{field} = ?"
              values << value
            end
          end
        end
        if persisted?
          sql_clause  << "id != ?"
          values << self.id
        end
        self.class.exists?([sql_clause.join(" AND "), *values])
      end
      
    end
  end
  
  module OnLoadActiveRecord
    include ActiveRecord::WithPermalink
  end
  
end