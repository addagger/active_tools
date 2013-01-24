require 'active_tools/core_extension/kabuki/crypt'
require 'active_tools/core_extension/kabuki/dump'
require 'active_tools/core_extension/kabuki/zip'

module ActiveTools
  module CoreExtension
    
    module Kabuki
      module ObjectExtension
        def kabuki!
          Base64.strict_encode64(self.kabuki_dump.kabuki_zip.kabuki_encrypt)
        end
      end

      module StringExtension
        def kabuki
          Base64.strict_decode64(self).kabuki_decrypt.kabuki_unzip.kabuki_load
        end
      end
      
      ::Object.send(:include, ObjectExtension)
      ::String.send(:include, StringExtension)
    end
  end
end