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
            when :apex_wsdl
                file_name = "apex.wsdl.xml"
            when :enums
                file_name = "enums.yml"
            when :describe_types
                file_name = "describe_label_type_map.yml"
        	else
        		file_name = param
        	end

        	File.expand_path(Resource_path + file_name, Rails.root)
        end
    end
end