module Metadata
    module Export
        class Mapping
            attr_reader :access_key
            attr_reader :row
            attr_reader :column
            attr_reader :needs_copy_row
            attr_reader :copy_start_row
            attr_reader :copy_end_row
            attr_reader :needs_join
            attr_reader :join_with

            def initialize(map_key, map_value)
                @access_key = map_key
                @row = map_value[:row]
                @column = map_value[:column]
                @copy_start_row = -1
                @copy_end_row = -1                      
                @join_with = []

                @needs_copy_row = map_value[:multi]
                if @needs_copy_row.nil?
                    @needs_copy_row = false
                end
                if @needs_copy_row
                    @copy_start_row = map_value[:start_row]
                    @copy_end_row = map_value[:end_row]
                end

                join = map_value[:join]
                @needs_join = !join.nil?

                if @needs_join
                    @join_with = join.map{ |key| key.to_sym}
                end
            end
        end
    end
end