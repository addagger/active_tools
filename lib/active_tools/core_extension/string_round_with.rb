module ActiveTools
  module CoreExtension
    
    module StringRoundWith
      module StringExtension
        def round_with(first, last = nil)
          last ||= first
          insert(0, first.to_s||"").insert(-1, last.to_s||"")
        end
      end
      ::String.send(:include, StringExtension)
    end
  end
end