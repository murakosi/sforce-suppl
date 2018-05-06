module Metadata
    class MetadataStore

        attr_reader :data
        attr_reader :current_full_name
        attr_reader :current_type

        def initialize
            clear()
        end

        def set_current(type, full_name)
            @current_type = type
            @current_full_name = full_name
        end

        def stored?(full_name)
            @data.has_stock?(full_name)
        end

        def [](full_name)
            @current_full_name = full_name
            @data[full_name]
        end

        def store_display(full_name, data)
            @data[full_name].display_data = data
        end

        def store_export(full_name, data)
            @data[full_name].export_data= data
        end

        def store_raw(full_name, data)
            @data[full_name].raw_data = data
        end

        def clear
            @current_full_name = nil
            @current_type = nil
            @data = StockHolder.new
        end

        class StockHolder
            
            def initialize()
                @stocks = {}
            end

            def has_stock?(key)
                @stocks.has_key?(key)
            end

            def [](key)
                if @stocks.has_key?(key)
                    @stocks[key]
                else
                    @stocks[key] = Stock.new
                end

            end
        end

        class Stock
            attr_accessor :display_data
            attr_accessor :export_data
            attr_accessor :raw_data

            def initialize()
                @display_data = {}
                @export_data = {}
                @raw_data = {}
            end
        end
    end
end