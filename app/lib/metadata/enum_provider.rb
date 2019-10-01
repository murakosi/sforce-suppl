require "fileutils"
require "yaml"

module Metadata
	class EnumProvider
	class << self

		def enums(deep_symbolize = false)
            enums_file = Service::ResourceLocator.call(:enums)
            if deep_symbolize 	
            	YAML.load_file(enums_file).deep_symbolize_keys
            else
            	YAML.load_file(enums_file)
            end
		end

		def enums!(create_file = false)
			tooling_wsdl = Service::ResourceLocator.call(:tooling_wsdl)
			enums = extract_enum_types(tooling_wsdl)
			if create_file
				create_enums_yaml(enums)
			end
			enums
		end

		def extract_enum_types(wsdl)
			enums = {}

			hash = Hash.from_xml(open(wsdl))
			schema = hash["definitions"]["types"]["schema"]
			simple_types = schema.map{|hash| hash["simpleType"]}.compact.flatten

			simple_types.each do |hash|
			    next unless hash.has_key?("restriction") && hash["restriction"].has_key?("enumeration")
			    name = hash["name"].camelize(:lower)
			    values = hash["restriction"]["enumeration"].to_a.flatten.map{|hash| hash["value"]}
			    enums[name] = values
			end

			add_missing_enums(enums)
		end

		def create_enums_yaml(enums)
			enums_file = Service::ResourceLocator.call(:enums)			
			enums_yml = enums.to_yaml
			if File.exist?(enums_file)
				FileUtils.remove(enums_file)
			end

			File.write(enums_file, enums_yml)
		end

		def add_missing_enums(enums)
			enums["visibility"] = enums["customSettingsVisibility"]
			enums["type"] = enums["fieldType"]
			enums
		end

	end
	end
end