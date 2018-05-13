module Describe
    module DescribeConstants
    
        Excel_map = {
                :no => 0,
                :label => 1, 
                :name => 2,
                :type => 3,
                :calculated_formula => 6,
                :length => 4,
                :picklist_values => 5,
                :nillable => 8,
                :custom => 9,
                :inline_help_text => 7,
                :default_value_formula => 10
            }

        def self.column_number(key)
            Excel_map[key]
        end
    end
end