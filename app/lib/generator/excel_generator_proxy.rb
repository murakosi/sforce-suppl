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
            @settings = YAML.load_file("./././resources/excel_export_settings.yml").deep_symbolize_keys
        end

        private
            def get_generator(key)
                template = File.expand_path(@settings[key][:template_name], Rails.root)
                mapping = File.expand_path(@settings[key][:mapping_name], Rails.root)
                case key.to_sym
	                when :ApprovalProcess
	                    Metadata::Export::ApprovalProcessExporter.new(template, mapping)
	                when :DescribeResult
	                	Generator::DescribeExcelGenerator.new(template, mapping)
	                else
	                    Metadata::Export::NilExporter.new(template, mapping)
                end
            end
    end
    end
end