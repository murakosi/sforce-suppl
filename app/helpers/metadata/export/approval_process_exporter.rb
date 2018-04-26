module Metadata
    module Export
        class ApprovalProcessExporter < Exporter

            def initialize(data, template, mapping)
                super(data, template, mapping)
                @export_file_name = "approval.xlsx"
            end

            def write_excel
                sheet = get_sheet(0)

                @mapping.each do | key, value  |
                    akey = @data.keys[key]
                    bkey = akey.first
                    #row = value[:row].to_i - 1
                    #col = value[:column].to_i - 1
                    cell = get_cell(value[:row], value[:column])
                    cell.change_contents(bkey[:value])
                    #sheet.add_cell(row, col, bkey[:value])
                end
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