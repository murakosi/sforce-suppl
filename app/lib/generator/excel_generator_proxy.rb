module Generator
    class ExcelGeneratorProxy
    class << self

        def generator(key)
            #if @settings.nil?
                load_settings
            #end

            get_generator(key)
        end
        
        def load_settings
            resource = Service::ResourceLocator.call(:excel_export_settings)
            @settings = YAML.load_file(resource).deep_symbolize_keys
        end

        private
            def get_generator(key)
                template = Service::ResourceLocator.call(@settings[key][:template_name])
                mapping = Service::ResourceLocator.call(@settings[key][:mapping_name])
                case key.to_sym
	                when :ApprovalProcess
	                    Generator::MetadataExcelGenerator.new(template, mapping)
	                when :DescribeResult
	                	Generator::DescribeExcelGenerator.new(template, mapping)
	                else
	                    Metadata::Export::NilExporter.new(template, mapping)
                end
            end
    end
    end
end