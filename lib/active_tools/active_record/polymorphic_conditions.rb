module ActiveTools
  module ActiveRecord
    module PolymorphicConditions
      extend ::ActiveSupport::Concern
      
      included do
      end
      
      module ClassMethods
      end
      
      def polymorphic_conditions(*args)
        conditions = []
        table = self.class.table_name
        stack = args.extract_options!
        sql_queries = stack.collect do |as_resource, hash|
          resource_queries = hash.map do |name, find_options|
            resource_class = name.to_s.classify.constantize
            resource_table = resource_class.table_name
            conditions << resource_class.name
            if find_options[:conditions].present?
              conditions += find_options[:conditions][1..-1]
            end
            joins_clause =
            Array.wrap(find_options[:join]).collect do |association|
              reflection = resource_class.reflections[association.to_s]            
              if reflection.macro == :belongs_to && reflection.options[:polymorphic] != true
                "INNER JOIN #{reflection.klass.table_name} ON #{reflection.active_record.table_name}.#{reflection.foreign_key} = #{reflection.klass.table_name}.id"
              elsif reflection.macro.in?([:has_many, :has_one]) && reflection.options[:as].nil?
                "INNER JOIN #{reflection.klass.table_name} ON #{reflection.klass.table_name}.#{reflection.foreign_key} = #{reflection.active_record.table_name}.id"
              end
            end.compact.join(" ").strip
            "(#{table}.#{as_resource}_type = ? AND EXISTS(#{["SELECT 1 FROM #{resource_table}#{joins_clause.left_indent(1) if joins_clause.present?} WHERE #{resource_table}.id = #{table}.#{as_resource}_id", find_options[:conditions].first].compact.join(" AND ")}))"
          end
          "CASE WHEN #{table}.#{as_resource}_type IS NOT NULL AND #{table}.#{as_resource}_id IS NOT NULL THEN #{resource_queries.join(" OR ")} ELSE TRUE END"
        end
        conditions.insert(0, "#{sql_queries.join(" OR ")}".send_if(:round_with, "(",")") {|q| q.present?})
      end
      
    end
  end
  
  module OnLoadActiveRecord
    include ActiveRecord::PolymorphicConditions
  end
  
end