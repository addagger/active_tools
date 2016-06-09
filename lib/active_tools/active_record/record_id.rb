module ActiveTools
  module ActiveRecord
    module RecordId
      extend ::ActiveSupport::Concern
      
      included do
      end
      
      module ClassMethods
      end
      
      def record_id
        "#{self.class.model_name.singular}_#{try(self.class.primary_key)||uniq_id}"
      end

      def uniq_id
        @_uniq_id ||= Base64.urlsafe_encode64(Time.now.send(:_dump))[0..-2]
      end
      
    end
  end
  
  module OnLoadActiveRecord
    include ActiveRecord::RecordId
  end
  
end