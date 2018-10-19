module Generator
	class DescribeCsvGenerator < CsvGenerator
		
		def generate(params)
			get_header(nil)
		    csv_data = CSV.generate(@csv_options) do |csv|
		      csv_column_names = params[:data].first.keys
		      csv << csv_column_names
		      params[:data].each do | hash |
		          csv << hash.values
		      end
		    end
		end

		def get_header(raw_header)
			translations = Translations::TranslationLocator[:describe_csv_header]
			p translations
		end
	end
end