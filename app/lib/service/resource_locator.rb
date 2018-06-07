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
        	when :excel_export_settings
        		file_name = "excel_export_settings.yml"
        	when :translations
        		file_name = "translations.yml"
        	else
        		file_name = param
        	end

        	File.expand_path(Resource_path + file_name, Rails.root)
        end
    end
end