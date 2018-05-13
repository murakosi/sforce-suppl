module Metadata
    module Export
        class NilExporter < Exporter

            def initialize(data, template, mapping)

            end

            def export
                nil
            end
        end
    end
end