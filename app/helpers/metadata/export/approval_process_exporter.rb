module Metadata
    module Export
        class ApprovalProcessExporter < Exporter

            def initialize(data, template, mapping)
                super(data, template, mapping)
                @export_file_name = "approval.xlsx"
            end

            def write_excel
                sheet = get_sheet(0)

                #p @data.keys
                @mapping.each do | key, value  |
                    akey = @data.keys[key]                    
                    next if akey.nil?
                    #bkey = akey.first
                    if value[:multi] && akey.size > 1
                        row_increment = value[:end_row] - value[:start_row]
                        akey.each do | hash |
                            copy_row(sheet, value[:start_row], value[:end_row]) 
                            set_content(value, hash, row_increment)              
                        end
                    else
                        #bkey = akey.first
                        set_content(value, akey.first)
                    end
                    #row = value[:row].to_i - 1
                    #col = value[:column].to_i - 1
                    #cell = get_cell(value[:row], value[:column])
                    #p "key =>" + key.to_s + ", " + "value =>" + bkey[:value].to_s
                    #cell.change_contents(bkey[:value].to_s)
                    
                end
            end

            def set_content(map, result, row_increment = 0)
                change_cell(map[:row] + row_increment, map[:column], result[:value])
            end

            def format(key, value)

            end

            Trans = {
                    :active => {true => "○", false => "×"},
                    :allow_recall => {true => "○", false => "×"}
                    }
        end
    end
end