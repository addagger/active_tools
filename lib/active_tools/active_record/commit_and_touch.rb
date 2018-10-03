module ActiveTools
  module ActiveRecord
    module CommitAndTouch
      extend ::ActiveSupport::Concern
      
      included do
      end
      
      module ClassMethods
        def commit_and_touch(*args, &block)
          options = args.extract_options!
          
          class_attribute :commit_and_touch_options unless defined?(commit_and_touch_options)
          self.commit_and_touch_options ||= {}
          self.commit_and_touch_options[:options] = options
          self.commit_and_touch_options[:reflections] = self.reflections.keys & args.map(&:to_s)
          
          after_commit options do
            self.commit_and_touch_options[:reflections].each do |assoc|
              attributes = if block_given?
                block.call(self)
              else
                {:updated_at => Time.now}
              end
              send(assoc).update_all(attributes)
            end
          end
        end
      end
      
    end
  end
  
  module OnLoadActiveRecord
    include ActiveRecord::CommitAndTouch
  end
  
end