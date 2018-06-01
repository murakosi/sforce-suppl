module Metadata
	class YamlFormatter
    class << self
		include Utils::FormatUtils

        Key_order = %i[type id full_name file_name created_date created_by_id created_by_name last_modified_date last_modified_by_id last_modified_by_name monegeable_state]

        def format(full_name, result)
            raw_data = RawData.new(full_name)
            raw_data.set_header(["key_name","value","number_of_items"])
            result.each do | k, v |
                raw_data.set_data([k.to_s, v.to_s, v.size.to_s])
            end

            raw_data
        end

        class RawData
            attr_reader :full_name
            attr_reader :header
            attr_reader :data

            def initialize(full_name)
                @full_name = full_name
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