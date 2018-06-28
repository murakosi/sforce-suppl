module Service
	class ResourceLocator
        include Service::ServiceCore
    
    	Resource_path = "./resources/"

        def call(param)
        	case param.to_sym
        	when :partner_wsdl
        		file_name = "partner.wsdl.xml"
        	when :metadata_wsdl
        		file_name = "metadata.wsdl.xml"
            when :tooling_wsdl
                file_name = "tooling.wsdl.xml"
        	when :excel_export_settings
        		file_name = "excel_export_settings.yml"
        	when :translations
        		file_name = "translations.yml"
            when :valuetypes
                file_name = "value_type_mappings.yml"
            when :enums
                file_name = "enums.yml"
        	else
        		file_name = param
        	end

        	File.expand_path(Resource_path + file_name, Rails.root)
        end
    end
end