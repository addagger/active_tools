module ActiveTools
  module CoreExtension
    
    module Kabuki
      class Dump
        def self.encode(object)
          Marshal.dump(object)
        end

        def self.decode(string)
          Marshal.load(string)
        end
      end

      module ObjectExtension
        def kabuki_dump
          Kabuki::Dump.encode(self)
        end
      end

      module StringExtension
        def kabuki_load
          Kabuki::Dump.decode(self)
        end
      end
      
      ::Object.send(:include, ObjectExtension)
      ::String.send(:include, StringExtension)
    end
  end
end