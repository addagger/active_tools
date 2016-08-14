module ActiveTools
  module ActionPack
    module ActionView
      module FieldName
        
      end
    end
  end
  
  module OnLoadActionView
    
    def field_name(builder, *args)
      [object_name_to_field_id(builder.object_name), *args].join("_")
    end
  
    def object_name_to_field_id(val)
      val.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")
    end
    
  end
  
end