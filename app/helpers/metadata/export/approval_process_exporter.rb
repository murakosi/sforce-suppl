module Metadata
    module Export
        class ApprovalProcessExporter < Exporter

            def initialize(data, template, mapping)
                super(data, template, mapping)
                @export_file_name = "approval.xlsx"
                @mapper = create_mapper(@mapping)
                @array_delimitter = "\n"
            end

            def write_excel
                sheet = get_sheet(0)

                @mapper.each do | map |
                    contents = @data[map.access_key]
                    next if contents.nil?

                    if require_loop(map, contents)
                        row_increment = map.copy_end_row - map.copy_start_row
                        contents.each do | content |
                            copy_row(sheet,  map.copy_start_row, map.copy_end_row) 
                            change_cell(map.row + row_increment, map.column, get_value(map, content))
                        end
                    else
                        change_cell(map.row, map.column, get_value(map, contents.first))
                    end
                    
                end
            end

            def require_loop(map, data_array)
                data_array.size > 1 && map.needs_copy_row
            end

            def get_value(map, current_content)
                if !map.needs_join
                    return get_string(current_content[:value])
                end

                values = []
                values << current_content[:value].to_s
                map.join_with.each do | join_key |                      
                    contents = @data[join_key].select{ |content| content[:index] = current_content[:index]}
                    values << get_string(contents.first[:value])
                end
                value = values.join(" ")
            end

            def get_string(value)
                if value.is_a?(Array)
                    value.join(@array_delimitter)
                else
                    value.to_s
                end
            end

            def create_mapper(mapping)
                mapping.map{ |k, v| Mapping.new(k, v)}
            end

            def trans(key, value)

            end
            Trans = {
                    :active => {true => "○", false => "×"},
                    :allow_recall => {true => "○", false => "×"}
                    }
            

        end
    end
end