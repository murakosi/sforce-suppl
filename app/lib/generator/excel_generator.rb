require "fileutils"
require "rubyXL"

module Generator
    class ExcelGenerator
        include Utils::ExcelUtils            
        include Generator::GeneratorCore
        
        def initialize(template, mapping)
            @template = template
            @mapping = load_symbolized_yaml(mapping)
        end

        def generate(data)
            prepare(data)
            begin
                edit()
                write_book()
            rescue => exception
                raise exception
            ensure
                remove_book()
            end
        end

        def edit
        end

        private
            def load_symbolized_yaml(yaml)
                YAML.load_file(yaml).deep_symbolize_keys
            end                

            def prepare(data)
                @data = data
                @output_file = allocate_output_file()
                FileUtils.cp(@template, @output_file)
                @workbook = RubyXL::Parser.parse(@output_file)
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
        
            def add_cell(row_no, column_no, value)
                row = row_no.to_i - 1
                column = column_no.to_i - 1
                @worksheet.add_cell(row, column, value)
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
                @workbook.write(@output_file)
                @workbook.stream.read
            end

            def remove_book
                FileUtils.rm(@output_file)
            end
    end
end