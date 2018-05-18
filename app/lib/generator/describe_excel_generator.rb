module Generator
	class DescribeExcelGenerator < ExcelGenerator

        def write_excel
        	sheet = get_sheet(0)

		    first_key = @mapping.keys.first
		    current_row = @mapping[first_key][:row]

		    #p @mapping
		    data_with_no_field.each_with_index do | values, index |
		    	sheet.insert_row(current_row)
		    	#p values
		      	values.each do | k, v |
			      	if @mapping.has_key?(k)
			      		column = @mapping[k][:column]			      		
			        	change_cell(current_row, column, v)
			        end
		      	end
		      	current_row += 1
		    end
        end

        def data_with_no_field
        	data_with_index = []
        	@data.each_with_index do | values, index |
        		data_with_index << values.merge({:no => index +  1})
        	end
        	data_with_index
        end
	end
end