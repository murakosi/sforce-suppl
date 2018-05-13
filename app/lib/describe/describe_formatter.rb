module Describe
    module DescribeFormatter
        Key_order = %i[label name type auto_number calculated calculated_formula external_id unique case_sensitive length digits scale precision picklist_values nillable custom inline_help_text default_value_formula] 
        Exclude_header = ["byte_length", "creatable", "defaulted_on_create",
                        "deprecated_and_hidden", "filterable", "groupable",
                        "id_lookup","name_field","name_pointing", "restricted_picklist",
                        "soap_type","sortable","updateable","auto_number","calculated",
                        "external_id","unique","case_sensitive",
                        "digits","scale","precision"]

        def self.format_field_result(field_result)
            get_values(field_result)
        end

        private

            def self.get_values(field_result)
                field_result.each{ |hash| change_value(hash) }.map{|hash| hash.slice(*Key_order)}
                            .map{|hash| hash.reject{|k,v| Exclude_header.include?(k.to_s) } }
            end

            def self.change_value(raw_hash)

                hash = add_key(raw_hash)

                create_type_hash()
                length_type = get_length_name(hash, @typeLabelMap[hash[:type]][:type])
                type_name = get_field_type_name(hash, @typeLabelMap[hash[:type]][:label])

                if hash[:type] == "picklist"
                    val = hash[:picklist_values].map{ |hash| hash[:value]}
                    hash[:picklist_values] = val.join("\n")
                end

                hash[:type] = type_name
                hash[:length] = length_type

                hash
            end

            def self.add_key(hash)
                if !hash.has_key?(:calculated_formula)
                hash.store(:calculated_formula, nil)
                end

                if !hash.has_key?(:external_id)
                hash.store(:external_id, nil)
                end

                if !hash.has_key?(:picklist_values)
                hash.store(:picklist_values, nil)
                end

                if !hash.has_key?(:inline_help_text)
                hash.store(:inline_help_text, nil)
                end
                
                if !hash.has_key?(:default_value_formula)
                hash.store(:default_value_formula, nil)
                end

                hash
            end

            def self.get_field_type_name(hash, raw_type_name)

                if hash[:auto_number]
                    type_name = "自動採番"
                elsif hash[:calculated]
                    type_name = "数式(" + raw_type_name + ")"      
                elsif hash[:external_id]
                    type_name = "（外部 ID）"
                elsif hash[:type] == "reference"
                    if hash[:reference_to].kind_of?(Array)
                        reference_value = hash[:reference_to].join(",\n")
                    else
                        reference_value = hash[:reference_to]
                    end
                    type_name = raw_type_name + "（" + reference_value + "）"
                elsif hash[:unique]
                    type_name = raw_type_name + "（ユニーク　"
                    if hash[:case_sensitive]
                        type_name += "大文字と小文字を区別する"
                    else
                        type_name += "大文字と小文字を区別しない"
                    end                
                else
                    type_name = raw_type_name
                end

                return type_name
            end

            def self.get_length_name(hash, lengthtype)

                if lengthtype == ""
                    length_name = hash[:length]
                elsif lengthtype == "NULL"
                    length_name = '';
                elsif lengthtype == "INT"
                    length_name = hash[:digits].to_s + ',0';
                elsif lengthtype == "DBL"
                    precision = hash[:precision]
                    scale = hash[:scale]
                    size = precision.to_i - scale.to_i
                    length_name = size.to_s + ',' + scale.to_s
                end

                return length_name
            end

            def self.create_type_hash
                if @typeLabelMap.present?
                    return
                end

                @typeLabelMap = Hash.new

                @typeLabelMap["id"] = {:label => "ID", :type => ""}
                @typeLabelMap["anytype"] = {:label => "AnyType", :type => ""}
                @typeLabelMap["base64"] = {:label => "Base64", :type => ""}
                @typeLabelMap["email"] = {:label => "電子メール", :type => ""}
                @typeLabelMap["phone"] = {:label => "電話", :type => ""}
                @typeLabelMap["combobox"] = {:label => "テキスト（＋選択リスト）", :type => ""}
                @typeLabelMap["encryptedstring"] = {:label => "パスワード", :type => ""}
                @typeLabelMap["string"] = {:label => "テキスト", :type => ""}
                @typeLabelMap["textarea"] = {:label => "テキストエリア", :type => ""}
                @typeLabelMap["url"] = {:label => "URL", :type => ""}
                @typeLabelMap["time"] = {:label => "時間", :type => ""}
                @typeLabelMap["boolean"] = {:label => "チェックボックス", :type => "NULL"}
                @typeLabelMap["date"] = {:label => "日付", :type => "NULL"}
                @typeLabelMap["datetime"] = {:label => "日付/時間", :type => "NULL"}
                @typeLabelMap["picklist"] = {:label => "選択リスト", :type => "NULL"}
                @typeLabelMap["multipicklist"] = {:label => "選択リスト(複数選択)", :type => "NULL"}
                @typeLabelMap["reference"] = {:label => "ルックアップ", :type => "NULL"}
                @typeLabelMap["int"] = {:label => "数値", :type => "INT"}
                @typeLabelMap["currency"] = {:label => "通貨", :type => "DBL"}
                @typeLabelMap["double"] = {:label => "数値", :type => "DBL"}
                @typeLabelMap["percent"] = {:label => "パーセント", :type => "DBL"}
            end
    end
end