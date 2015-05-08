module ActiveTools
  module ActionPack
    module ActionView
      module PerformAsTree
        def self.line(item, children_method, depth = 0, &block)
          yield item, depth
          item.send(children_method).each do |child|
            line(child, children_method, depth+1, &block)
          end
        end
      end
    end
  end
  
  module OnLoadActionView
    
    def perform_as_tree(scope, options = {}, &block)
      options = options.with_indifferent_access
      children_method = options[:children_method]||:children
      parent_method = options[:parent_method]||:parent
      id_key = options[:id]||nil
      scope = case scope
      when ::ActiveRecord::Relation then
        parent_key = scope.klass.reflections[children_method.to_s].foreign_key
        scope.where(parent_key => id_key)
      when ::Array, ::Set then
        scope.select {|item| item.send(parent_method) == id_key}
      else
        raise(TypeError, "ActiveRecord::Relation, Array or Set expected, #{scope.class.name} passed!")
      end
      scope.each do |item|
        ActionPack::ActionView::PerformAsTree.line(item, children_method, 0, &block)
      end
    end
    
  end
  
end