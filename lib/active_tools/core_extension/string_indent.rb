module ActiveTools
  module CoreExtension
    
    module StringIndent
      module StringExtension
        def nobr
          self.gsub(/\r/," ").gsub(/\n/," ")
        end

        def both_indent(*args)
          indent_size = args.delete_at(0)
          raise(TypeError, "Fixnum expected, #{indent_size.class} passed") unless indent_size.is_a?(Fixnum)
          center(size+indent_size*2, *args)
        end

        def left_indent(*args)
          indent_size = args.delete_at(0)
          raise(TypeError, "Fixnum expected, #{indent_size.class} passed") unless indent_size.is_a?(Fixnum)
          rjust(size+indent_size, *args)
        end

        def right_indent(*args)
          indent_size = args.delete_at(0)
          raise(TypeError, "Fixnum expected, #{indent_size.class} passed") unless indent_size.is_a?(Fixnum)
          ljust(size+indent_size, *args)
        end
      end
      ::String.send(:include, StringExtension)
    end
  end
end