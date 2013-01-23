module ActiveTools
  module CoreExtension
    
    module Kabuki
      class Crypt
        def initialize(string, key = nil)
          @key = key||Digest::SHA1.hexdigest("yourpass")
          @string = string
        end

        def encode
          c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
          c.encrypt
          c.key = @key
          e = c.update(@string)
          e << c.final
          e
        end

        def decode
          c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
          c.decrypt
          c.key = @key
          d = c.update(@string)
          d << c.final
          d
        end
      end

      module StringExtension
        def kabuki_encrypt
          Kabuki::Crypt.new(self).encode
        end

        def kabuki_decrypt
          Kabuki::Crypt.new(self).decode
        end
      end
      
      ::String.send(:include, StringExtension)
    end
  end
end