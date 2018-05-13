module Metadata
    class HelperProxy
    class << self

        def load_settings
            @settings = YAML.load_file("./././resources/metadata_export.yml")
        end

        def get_exporter(key, data)
            #if @settings.nil?
                load_settings
            #end

            exporter(key, data)
        end

        private
            def exporter(key, data)
                template = File.expand_path(@settings[key]["template_name"], Rails.root)
                mapping = File.expand_path(@settings[key]["mapping_name"], Rails.root)
                case key.to_sym
                when :ApprovalProcess
                    Metadata::Export::ApprovalProcessExporter.new(data, template, mapping)
                else
                    Metadata::Export::NilExporter.new(data, template, mapping)
                end
            end
    end
    end
end