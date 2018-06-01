module Generator
	class MetadataYamlGenerator

		def generate(params)
	        yaml_data = Metadata::MetadataFormatter.format(Metadata::MetadataFormatType::Yaml, params[:full_name], params[:data])
	        yaml = []
	        yaml_data.data.each do | data |
	            yaml << data[0].to_s + ":"
	            yaml << "    row: "
	            yaml << "    column: "
	            yaml << "    multi: false"
	            yaml << "    start_row: 0"
	            yaml << "    end_row: 0"
	            yaml << "    join:"
	        end
	        yaml.join("\n")
		end
	end
end