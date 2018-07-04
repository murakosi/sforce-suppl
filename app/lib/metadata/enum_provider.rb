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

	end
	end
end