require "csv"

module Generator
	class CsvGenerator
		
		def initialize(encoding, line_feed, force_quotes)
			@csv_options = {:encoding => encoding, :row_sep => line_feed, :force_quotes => force_quotes}
		end

		def generate(params)
		end
	end
end