module Metadata
    class Formatter
        class << self
        include Metadata::DisplayFormatter
        include Metadata::ExportFormatter

            def metadata_store
                if @metadata_store.present?
                    @metadata_store
                else
                    @metadata_store = Metadata::MetadataStore.new
                end
            end
            
            def format(read_result, full_name)
                metadata_store.set_current(read_result[:"@xsi:type"], full_name)
                metadata_store.store_display(full_name, format_for_display(read_result, full_name))
                metadata_store.store_export(full_name, format_for_export(read_result))
                metadata_store.store_raw(full_name, get_raw_data(metadata_store[full_name].export_data))
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

                def get_raw_data(keys)
                    raw_data = RawData.new(["key_name","value","is_array"])
                    keys.each do | k, v |
                        raw_data.set_data([k.to_s, v.first[:value].to_s, v.size > 1])
                    end                
                    raw_data
                end

                class RawData
                    attr_reader :header
                    attr_reader :data

                    def initialize(header)
                        @header = header
                        @data = []
                    end

                    def set_data(data)
                        @data << data
                    end
                end
        end
    end
end