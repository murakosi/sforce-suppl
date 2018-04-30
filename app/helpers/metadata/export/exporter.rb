require "fileutils"
require "rubyXL"

module Metadata
    module Export
        include ExcelUtils
        class Exporter
            

            Output_file = File.expand_path("./output/output.xlsx", Rails.root)

            def initialize(data, template, mapping)
                @data = data
                @template = template
                @mapping = load_symbolized_yaml(mapping)
                @export_file_name = nil
            end

            def export
                prepare
                begin
                    write_excel
                    write_book
                rescue => exception
                    raise exception
                ensure
                    remove_book
                end
            end

            def write_excel
            end

            private
                def load_symbolized_yaml(yaml)
                    YAML.load_file(yaml).deep_symbolize_keys
                end                

                def prepare
                    FileUtils.cp(@template, Output_file)
                    @workbook = RubyXL::Parser.parse(Output_file)
                end

                def workbook
                    @workbook
                end

                def get_sheet(index, name = nil)
                    if name.nil?
                        @worksheet = @workbook[index]
                    else
                        @worksheet = @workbook[name]
                    end
                end
            
                def change_cell(row_no, column_no, value)
                    cell = get_cell(row_no, column_no)

                    if cell.nil?
                        p row_no
                        p column_no
                        raise StandardError.new("Cell is null")
                    else
                        cell.change_contents(value)
                    end
                end

                def get_cell(row_no, column_no)
                    row = row_no.to_i - 1
                    column = column_no.to_i - 1
                    @worksheet[row][column]
                end

                def write_book()
                    @workbook.write(Output_file)
                    OutputResult.new(@workbook.stream.read, @export_file_name)
                end

                def remove_book
                    FileUtils.rm(Output_file)
                end
        end
    end
end