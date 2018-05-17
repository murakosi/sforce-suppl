module Generator
	class DescribeCsvGenerator < CsvGenerator

		def generate(params)
			csv_options = {:encoding => @encoding, :row_sep => @line_feed, :force_quotes => @force_quotes}

		    csv_data = CSV.generate(csv_options) do |csv|
		      csv_column_names = params[:data].first.keys
		      csv << csv_column_names
		      params[:data].each do | hash |
		          csv << hash.values
		      end
		    end
		end
	end
end