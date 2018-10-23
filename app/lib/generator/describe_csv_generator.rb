module Generator
	class DescribeCsvGenerator < CsvGenerator
		
		def generate(params)			
		    csv_data = CSV.generate(@csv_options) do |csv|
		      csv_column_names = get_header(params[:data].first.keys)
		      csv << csv_column_names
		      params[:data].each do | hash |
		          csv << hash.values
		      end
		    end
		end

		def get_header(raw_header)
			if raw_header.nil?
				return raw_header
			end
			
			translation = Translations::TranslationLocator.instance[:describe_csv_header]

			header = []
			raw_header.each do | value |
				header << translation[value]
			end
			header

		end
	end
end