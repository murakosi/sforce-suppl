module DescribeHelper

    def self.describe_global(client)
        result = client.describe_global()
        @global_result = result[:sobjects].map { |sobject| {:name => sobject[:name], :is_custom => sobject[:custom]} }
    end

    def self.is_global_fetched?
        @global_result.present?
    end

    def self.global_result
        @global_result
    end

    def self.describe(client, object_name)
        result = client.describe(object_name)
        @object_result = result
    end

    def self.object_result
        @object_result
    end

    def self.field_type_name(field_type)
        create_type_hash
        @typeLabelMap[field_type][:label]        
    end

    def self.field_length_type(field_type)
        create_type_hash
        @typeLabelMap[field_type][:type]  
    end

    private
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
