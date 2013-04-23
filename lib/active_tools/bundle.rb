module ActiveTools
  module OnLoadActiveRecord
    extend ::ActiveSupport::Concern
  end
  
  module OnLoadActionController
    extend ::ActiveSupport::Concern
  end
  
  module OnLoadActionView
    extend ::ActiveSupport::Concern
  end
  
  module Bundle
    require 'active_tools/core_extension'
    require 'active_tools/actionpack'
    require 'active_tools/activesupport'
    require 'active_tools/activemodel'
    require 'active_tools/activerecord'
    require 'active_tools/misc'
  end
end