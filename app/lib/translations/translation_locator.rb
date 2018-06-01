require "singleton"

module Translations
	class TranslationLocator
		include Singleton

		def initialize
			@locator = YAML.load_file("./././resources/translations.yml").deep_symbolize_keys
			@translations = {}
		end

		def [](key)
			
			#if @translations.has_key?(key)
			#	@translations[key]
			#else
				relative_path = @locator[key]
				full_path = File.expand_path(relative_path, Rails.root)
				@translations[key] = YAML.load_file(full_path).deep_symbolize_keys
			#end
		end
	end
end