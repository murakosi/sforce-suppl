module Metadata
    class Parser
    class << self
    include DisplayFormatter
    include ExportFormatter     

        def metadata_store
            if @metadata_store.present?
                @metadata_store
            else
                @metadata_store = Metadata::MetadataStore.new
            end
        end
        
        def parse(read_result, full_name)
            metadata_store.set_current(read_result[:"@xsi:type"], full_name)
            metadata_store.store_display(full_name, format_for_display(read_result, full_name))
            metadata_store.store_export(full_name, format_for_export(read_result))
            metadata_store.store_raw(full_name, get_raw_data(read_result[:"@xsi:type"], metadata_store[full_name].export_data))
            metadata_store[full_name]
        end

        def format_metadata_list(metadata_list)
            metadata_list.map{ |hash| hash.slice(*Key_order)}.sort_by{|k,v| k[:full_name]}
        end

        def format_tree_nodes(metadata_list)
            get_tree_parent_nodes(metadata_list)
        end

        private
            Key_order = %i[type id full_name file_name created_date created_by_id created_by_name last_modified_date last_modified_by_id last_modified_by_name monegeable_state]

            def get_raw_data(type, keys)
                raw_data = RawData.new(type)
                raw_data.set_header(["key_name","value","number_of_items"])
                keys.each do | k, v |
                    raw_data.set_data([k.to_s, v.to_s, v.size.to_s])
                end

                raw_data
            end

            class RawData
                attr_reader :type
                attr_reader :header
                attr_reader :data

                def initialize(type)
                    @type = type
                    @data = []
                end

                def set_header(header)
                    @header = header
                end

                def set_data(data)
                    @data << data
                end
            end
    end
    end
end