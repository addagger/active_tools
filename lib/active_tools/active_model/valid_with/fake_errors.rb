module ActiveTools
  module ActiveModel
    module ValidWith
      class FakeErrors < ::ActiveModel::Errors
        private
        def normalize_message(attribute, message, options)
          message ||= :invalid
        end
      end
    end
  end
end