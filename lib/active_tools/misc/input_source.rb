module ActiveTools
  module Misc
    module InputSource
      module ErrorsExtension
        extend ::ActiveSupport::Concern

        included do
          delegate :field_of, :to => :@base
        end

        def fields
          keys.map {|attribute| field_of(attribute)}.compact.tap do |names|
            names.instance_eval do
              def ids
                self.map(&:to_id)
              end
            end
          end
        end
      end
      
      module ConverseParameters
        def converse_parameters(value, prefix = nil, parent = nil)
          case value
          when Hash
            value.each do |k, v|
              new_prefix = prefix ? "#{prefix}[#{k}]" : k
              converse_parameters(v, new_prefix, value)
            end
          when Array
            value.each do |e|
              new_prefix = "#{prefix}[]"
              converse_parameters(e, new_prefix, value)
            end
          else
            value
          end
          value.tap do |v|
            v.singleton_class.send(:undef_method, :belongs_to) if v.respond_to?(:belongs_to)
            v.define_singleton_method :belongs_to do
              parent
            end
            v.singleton_class.send(:undef_method, :input_source) if v.respond_to?(:input_source)
            v.define_singleton_method :input_source do
              prefix.to_s
            end
          end
        end
      end
      
      module RequestExtension
        include ConverseParameters

        private
        def normalize_parameters(value)
          converse_parameters(super)
        end
      end
      
      module AttributesAssignment
        def assign_attributes(*args)
          new_attributes = args.first
          if new_attributes.respond_to?(:input_source)
            @input_source = new_attributes.input_source
          end
          super(*args)
        end

        def field_of(attribute)
          if @input_source && has_attribute?(attribute)
            "#{@input_source}[#{attribute}]".tap do |input_source|
              input_source.instance_eval do
                def to_id
                  self.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")
                end
              end
            end
          end
        end
      end
    
    end
  end
  
  module OnLoadActionController
    ::ActionDispatch::Request.send(:include, Misc::InputSource::RequestExtension)
    
    def converse(hash, key)
      converse_parameters(hash[key], key)
    end

    private
    include Misc::InputSource::ConverseParameters
  end
  
  module OnLoadActiveRecord
    ::ActiveModel::Errors.send(:include, Misc::InputSource::ErrorsExtension)
    
    if Rails.version >= "3.2.9"
      ::ActiveRecord::AttributeAssignment.send(:include, Misc::InputSource::AttributesAssignment)
    else
      include Misc::InputSource::AttributesAssignment
    end
  end
end