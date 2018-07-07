require "fileutils"
class TypeParser
class << self
		SoapTypes = [
			"anytype",
			"base64binary",
			"boolean",
			"date",
			"datetime",
			"double",
			"id",
			"integer",
			"string",
			"time"			
		]

def do_parse
		
    h = [{:is_foreign_key=>false, :is_name_field=>true, :min_occurs=>"0", :name=>"fullName", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"active", :soap_type=>"boolean", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"allowRecall", :soap_type=>"boolean", :value_required=>true}, {:fields=>[{:foreign_key_domain=>["Group", "Role", "UserMapped"], :is_foreign_key=>true, :is_name_field=>false, :min_occurs=>"0", :name=>"submitter", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"type", :picklist_values=>[{:active=>true, :default_value=>false, :label=>nil, :value=>"group"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"role"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"user"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"roleSubordinates"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"roleSubordinatesInternal"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"owner"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"creator"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"accountOwner"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"ownerDelegate"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"creatorDelegate"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"accountOwnerDelegate"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"partnerUser"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"customerPortalUser"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"portalRole"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"portalRoleSubordinates"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"allInternalUsers"}], :soap_type=>"ProcessSubmitterType", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"allowedSubmitters", :soap_type=>"ApprovalSubmitter", :value_required=>true}, {:fields=>{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"field", :soap_type=>"string", :value_required=>true}, :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"approvalPageFields", :soap_type=>"ApprovalPageField", :value_required=>true}, {:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"allowDelegate", :soap_type=>"boolean", :value_required=>true}, {:fields=>{:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"name", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"type", :soap_type=>"WorkflowActionType", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"action", :soap_type=>"WorkflowActionReference", :value_required=>true}, :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"approvalActions", :soap_type=>"ApprovalAction", :value_required=>true}, {:fields=>[{:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"name", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"type", :picklist_values=>[{:active=>true, :default_value=>false, :label=>nil, :value=>"adhoc"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"user"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"userHierarchyField"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"relatedUserField"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"queue"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"apexMethod"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"PreviousApprover"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"none"}], :soap_type=>"NextOwnerType", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"approver", :soap_type=>"Approver", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"whenMultipleApprovers", :picklist_values=>[{:active=>true, :default_value=>false, :label=>nil, :value=>"Unanimous"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"FirstResponse"}], :soap_type=>"RoutingType", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"assignedApprover", :soap_type=>"ApprovalStepApprover", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"description", :soap_type=>"string", :value_required=>true}, {:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"booleanFilter", :soap_type=>"string", :value_required=>true}, {:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"field", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"value", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"valueField", :soap_type=>"string", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"criteriaItems", :soap_type=>"FilterItem", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"formula", :soap_type=>"string", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"entryCriteria", :soap_type=>"ApprovalEntryCriteria", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"ifCriteriaNotMet", :picklist_values=>[{:active=>true, :default_value=>false, :label=>nil, :value=>"ApproveRecord"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"RejectRecord"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"GotoNextStep"}], :soap_type=>"StepCriteriaNotMetType", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"label", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"name", :soap_type=>"string", :value_required=>true}, {:fields=>{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"type", :picklist_values=>[{:active=>true, :default_value=>false, :label=>nil, :value=>"RejectRequest"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"BackToPrevious"}], :soap_type=>"StepRejectBehaviorType", :value_required=>true}, :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"rejectBehavior", :soap_type=>"ApprovalStepRejectBehavior", :value_required=>true}, {:fields=>{:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"name", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"type", :soap_type=>"WorkflowActionType", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"action", :soap_type=>"WorkflowActionReference", :value_required=>true}, :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"rejectionActions", :soap_type=>"ApprovalAction", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"approvalStep", :soap_type=>"ApprovalStep", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"description", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"emailTemplate", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"enableMobileDeviceAccess", :soap_type=>"boolean", :value_required=>true}, {:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"booleanFilter", :soap_type=>"string", :value_required=>true}, {:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"field", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"value", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"valueField", :soap_type=>"string", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"criteriaItems", :soap_type=>"FilterItem", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"formula", :soap_type=>"string", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"entryCriteria", :soap_type=>"ApprovalEntryCriteria", :value_required=>true}, {:fields=>{:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"name", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"type", :soap_type=>"WorkflowActionType", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"action", :soap_type=>"WorkflowActionReference", :value_required=>true}, :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"finalApprovalActions", :soap_type=>"ApprovalAction", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"finalApprovalRecordLock", :soap_type=>"boolean", :value_required=>true}, {:fields=>{:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"name", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"type", :soap_type=>"WorkflowActionType", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"action", :soap_type=>"WorkflowActionReference", :value_required=>true}, :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"finalRejectionActions", :soap_type=>"ApprovalAction", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"finalRejectionRecordLock", :soap_type=>"boolean", :value_required=>true}, {:fields=>{:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"name", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"type", :soap_type=>"WorkflowActionType", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"action", :soap_type=>"WorkflowActionReference", :value_required=>true}, :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"initialSubmissionActions", :soap_type=>"ApprovalAction", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"label", :soap_type=>"string", :value_required=>true}, {:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"useApproverFieldOfRecordOwner", :soap_type=>"boolean", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"userHierarchyField", :soap_type=>"string", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"nextAutomatedApprover", :soap_type=>"NextAutomatedApprover", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"postTemplate", :soap_type=>"string", :value_required=>true}, {:fields=>{:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"name", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"type", :soap_type=>"WorkflowActionType", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"action", :soap_type=>"WorkflowActionReference", :value_required=>true}, :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"recallActions", :soap_type=>"ApprovalAction", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"recordEditability", :picklist_values=>[{:active=>true, :default_value=>false, :label=>nil, :value=>"AdminOnly"}, {:active=>true, :default_value=>false, :label=>nil, :value=>"AdminOrCurrentApprover"}], :soap_type=>"RecordEditabilityType", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"showApprovalHistory", :soap_type=>"boolean", :value_required=>true}]
    
    name = "CustomObject"
    @result = []
    @i = 0
    h.each{|hash| parse_hash(hash)}
    
    if File.exist?("parse.log")
    	FileUtils.remove("parse.log")
    end

    file = File.open('parse.log','a')
    @result.each do |h|
        #file.puts h
        h.each do |k,v|
            if v[:min_occurs].to_i > 0
                req = " !!!!!!!!!!!!!!"
            else
                req = ""
            end
            file.puts k + " = " + v[:name] + "@" + v[:soap_type] + req
        end
    end
    file.close
    #File.write("parse.log", Hash[*@result])
    
    chk = {}
    @result.each do |h|
        h.each do |k,v|
            if chk.has_key?(k)
                raise Exception.new(k)
            else
                chk[k] = v
            end
        end
    end
end

def do_f(p, h)
    rem = h.delete(:fields)
    if p.nil?
        #hk = get_soap(h)
        pk = h[:name]
    else
        pk = p
    end
    parse_hash(h, pk)
    #parse_hash(h,hk)

    if !rem.nil?
        rem = Array[rem].flatten
        rem.each do |hash|
            parse_hash(hash, get_key(pk, hash[:name]))
        end
    end
end

        def parse_hash(hash, parent = nil)
            #hashes = Array[hashes].flatten
            hash.each do |k, v|
                if k == :fields
                    do_f(parent, hash)
                else
                    if parent.nil?
                        @result << {hash[:name] => hash}
                    else
                        #@result << {parent => { hash[:name] => hash }}
                        @result << {parent => hash }
                    end
                end
                break
            end
            @result
        end
        
        def get_key(p, c)
            if p.nil?
                c.to_s
            else
                p.to_s + "." + c.to_s
            end
        end
        
        def get_soap(arr)
            arr = Array[arr].flatten
            arr.each do | hash|
                if hash[:soap_type].to_s.downcase.end_with?("enum")
                    next
                elsif SoapTypes.include?(hash[:soap_type].to_s.downcase)
                    next
                else
                    #return get_key(hash[:soap_type],hash[:name])
                    #return hash[:name]
                    return hash[:soap_type]
                end
            end
        end
        
        def parse_child(parent, hash)
            hash.each do |k, v|
                if v.is_a?(Hash)
                    id = get_id(parent, k)
                    #remodel(id, parent, key_text(k), false)
                    parse_child(id, v, index)
                elsif v.is_a?(Array)
                    if is_hash_array?(v)
                        v.each_with_index do |item, idx|
                            id = get_id(parent, k, idx)
                            #remodel(id, parent, key_text(k, idx), false)
                            parse_child(id, item, idx)
                        end
                    else
                        key_id = get_id(parent, k)
                        value_id = get_id(key_id, "value")
                        #create_value_node(parent, key_id, k, value_id, v.join(","))
                        remodel(key_id, v)
                    end
                else
                    key_id = get_id(parent, k)
                    value_id = get_id(key_id, "value")
                    #create_value_node(parent, key_id, k, value_id, v)
                    remodel(key_id, v)
                end
            end
        end

        def get_id(parent, current, index = nil)
            if index.nil?
                id = parent.to_s + "/" + current.to_s
            else
                id = parent.to_s + "/" + current.to_s + "[" + index.to_s + "]"
            end
        end

        #def remodel(id, parent_id, text, editable, path = nil)
        def remodel(id, hash)
            
            @result[id] = hash
        end
        
        def is_hash_array?(array)
            if array.is_a?(Array)
                array.all?{ |item| item.is_a?(Hash) }
            else
                false
            end
        end
end
end