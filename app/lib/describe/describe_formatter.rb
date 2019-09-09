module Describe
    class DescribeFormatter
        class << self

        Key_order = %i[label name type reference_to 
                    length picklist_values picklist_lables 
                    calculated_formula auto_number external_id calculated 
                    digits scale precision custom unique 
                    case_sensitive nillable inline_help_text 
                    default_value_formula] 
        Exclude_header = [:byte_length, :creatable, :defaulted_on_create,
                        :deprecated_and_hidden, :filterable, :groupable,
                        :id_lookup,:name_field, :name_pointing, :restricted_picklist,
                        :soap_type, :sortable, :updateable,:calculated,
                        :digits, :scale, :precision
                        ]

        def format(field_result)
            @translation = Translations::TranslationLocator.instance[:describe_field_result]
            get_values(field_result)
        end

        private

            def get_values(field_result)
                Array[field_result].flatten.each{ |hash| translate_value(hash) }.map{|hash| hash.slice(*Key_order)}
                            .map{|hash| hash.reject{|k,v| Exclude_header.include?(k) } }
            end

            def translate_value(raw_hash)

                add_missing_key(raw_hash)

                translate_key = raw_hash[:type].to_sym
                if @translation.has_key?(translate_key)
                    type = get_type_name(raw_hash, @translation[translate_key][:label])
                    length = get_length_name(raw_hash, @translation[translate_key][:type])
                else
                    type = raw_hash[:type]
                    length = nil
                end

                if raw_hash[:type] == "picklist"
                    picklist_values = raw_hash[:picklist_values]                    
                    raw_hash[:picklist_values] = get_picklist_values(picklist_values)
                    raw_hash[:picklist_lables] = get_picklist_labels(picklist_values)
                end

                if raw_hash[:type] == "reference"
                    if raw_hash[:reference_to].kind_of?(Array)
                        reference_value = raw_hash[:reference_to].join("\n")
                    else
                        reference_value = raw_hash[:reference_to]
                    end
                    raw_hash[:reference_to] = reference_value
                end

                raw_hash[:type] = type
                raw_hash[:length] = length

                raw_hash
            end

            def get_picklist_values(picklist_values)

                values = ""
                
                if picklist_values.is_a?(Array)
                    values = picklist_values.map{ |hash| hash[:value]}
                end
                
                if picklist_values.is_a?(Hash)
                    values = [picklist_values[:value]]
                end
                
                values.join("\n")
            end

            def get_picklist_labels(picklist_values)

                labels = ""

                if picklist_values.is_a?(Array)
                    labels = picklist_values.map{ |hash| hash[:label]}
                end
                
                if picklist_values.is_a?(Hash)
                    labels = [picklist_values[:label]]
                end
                
                labels.join("\n")
            end

            def add_missing_key(raw_hash)

                if !raw_hash.has_key?(:reference_to)
                    raw_hash.store(:reference_to, nil)
                end

                if !raw_hash.has_key?(:calculated_formula)
                    raw_hash.store(:calculated_formula, nil)
                end

                if !raw_hash.has_key?(:external_id)
                    raw_hash.store(:external_id, nil)
                end

                if !raw_hash.has_key?(:picklist_values)
                    raw_hash.store(:picklist_values, nil)
                end

                if !raw_hash.has_key?(:picklist_lables)
                    raw_hash.store(:picklist_lables, nil)
                end

                if !raw_hash.has_key?(:inline_help_text)
                    raw_hash.store(:inline_help_text, nil)
                end
                
                if !raw_hash.has_key?(:default_value_formula)
                    raw_hash.store(:default_value_formula, nil)
                end

                raw_hash
            end

            # unsed
            def get_type_name(raw_hash, raw_type_name)

                if raw_hash[:auto_number]
                    return @translation[:auto_number][:label]
                end

                if raw_hash[:calculated]
                    return @translation[:formula][:label] + "(" + raw_type_name + ")"
                end

                if raw_hash[:external_id]
                    return @translation[:external_id][:label]
                end
=begin
                if raw_hash[:type] == "reference"
                    if raw_hash[:reference_to].kind_of?(Array)
                        reference_value = raw_hash[:reference_to].join(",\n")
                    else
                        reference_value = raw_hash[:reference_to]
                    end
                    return raw_type_name + "（" + reference_value + "）"
                end
=end
                return raw_type_name
            end
            
            def get_length_name(raw_hash, data_type)

                if data_type.empty?
                    return data_type
                end

                if data_type == "string"
                    return raw_hash[:length].to_s;
                end

                if data_type == "integer"
                    return raw_hash[:digits].to_s + ',0';
                end

                if data_type == "double"
                    precision = raw_hash[:precision]
                    scale = raw_hash[:scale]
                    size = precision.to_i - scale.to_i
                    return size.to_s + ',' + scale.to_s
                end

                raise StandardError.new("No datatype specified")
            end
        end
    end
end
