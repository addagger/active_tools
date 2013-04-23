module ActiveTools
  module ActiveModel
    module RecordId
      extend ::ActiveSupport::Concern
      
      included do
      end
      
      module ClassMethods
      end
      
      def record_id
        "#{self.class.model_name.singular}_#{try(:id)||uniq_id}"
      end

      def uniq_id
        Base64.urlsafe_encode64(Time.now._dump)
      end
      
    end
  end
  
  module OnLoadActiveRecord
    include ActiveModel::RecordId
  end
  
end