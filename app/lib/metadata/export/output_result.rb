module Metadata
    module Export
        class OutputResult

            attr_reader :data
            attr_reader :file_name
            
            def initialize(data, file_name)
                @data = data
                @file_name = file_name
            end
        end
    end
end