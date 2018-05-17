module Generator
	class DescribeExcelGenerator < ExcelGenerator

        def write_excel
        	sheet = get_sheet(0)
		    row_incremental_value = 0
		    @data.each do | values |
		      values.each do | k, v |
		      	if @mapping.has_key?(k)
		      		row = @mapping[k][:row] + row_incremental_value
		      		column = @mapping[k][:column]
		      		sheet.insert_row(row + 1)
		        	#change_cell(row, column, v)
		        end
		      end
		      row_incremental_value += 1
		    end
        end
	end
end