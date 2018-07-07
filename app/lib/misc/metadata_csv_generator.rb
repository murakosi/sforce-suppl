module Generator
	class MetadataCsvGenerator < CsvGenerator
		include Metadata::Formatter

		def generate(params)
			yaml_data = format(Metadata::FormatType::Yaml, params[:full_name], params[:data])
	        csv_date = CSV.generate(@csv_options) do |csv|
	            csv_column_names = yaml_data.header
	            csv << csv_column_names
	            yaml_data.data.each do | data |
	                csv << data
	            end
	        end
		end
		
	end
end