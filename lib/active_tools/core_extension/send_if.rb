module ActiveTools
  module CoreExtension
    
    module SendIf
      module ObjectExtension
        def send_if(*args, &block)
          if yield(self) == true
            send(*args)
          else
            self
          end
        end
      end
      ::Object.send(:include, ObjectExtension)
    end
  end
end