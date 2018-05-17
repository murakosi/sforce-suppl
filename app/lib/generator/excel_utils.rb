require "rubyXL"

module Generator
    module ExcelUtils

        def copy_row(sheet, copy_from, copy_to)
            rows_to_copy = []
            added_rows = []
            start_row_no = copy_from.to_i - 1
            end_row_no = copy_to.to_i - 1
            copy_count = end_row_no - start_row_no

            for i in 0..copy_count
                row_no = start_row_no + i
                rows_to_copy << sheet[row_no].clone
                added_rows << sheet.insert_row(end_row_no)
            end

            if sheet.merged_cells.present?
                sheet.merged_cells.each do |cell| next unless cell.ref.row_range.min >= end_row_no
                    cell.ref.instance_variable_set(:"@row_range", Range.new(cell.ref.row_range.min + copy_count, cell.ref.row_range.max + copy_count))
                end

                sheet.merged_cells.each do |cell| next unless cell.ref.row_range.min >= start_row_no && cell.ref.row_range.max < start_row_no + copy_count
                    sheet.merge_cells(cell.ref.row_range.min + copy_count, cell.ref.col_range.min, cell.ref.row_range.max + copy_count, cell.ref.col_range.max)
                end
            end

            rows_to_copy.reverse.each_with_index do |row, row_idx |
                row.cells.each_with_index do | cell, cell_idx|
                    added_rows[row_idx].cells[cell_idx] = row.cells[cell_idx].clone
                end
            end                
        end
    end
end