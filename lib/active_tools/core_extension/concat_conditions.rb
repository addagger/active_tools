module ActiveTools
  module CoreExtension
    
    module ConcatConditions
      module ArrayExtension
        def concat_as_condition_with(*args)
          options = args.extract_options!
          conditions = args.first||[]
          operator = options[:operator]||"AND"
          round = options[:round]||false
          concat_array = [self[0],conditions[0]].compact
          sql_clause = concat_array.present? ? concat_array.join(" #{operator} ") : nil
          [(round && concat_array.size > 1) ? "(#{sql_clause})" : sql_clause, *((self[1..-1]||[])+(conditions[1..-1]||[]))]
        end
        def concat_as_condition_with!(*args)
          replace(concat_as_condition_with(*args))
        end
      end
      ::Array.send(:include, ArrayExtension)
    end
  end
end