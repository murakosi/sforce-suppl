h = {:fields=>
[
{:name=>"actionName", :soap_type=>"string", :value_required=>true},
{:name=>"comment", :soap_type=>"string", :value_required=>true},
{:name=>"content", :soap_type=>"string", :value_required=>true},
{:name=>"formFactor", :picklist_values=>[], :soap_type=>"FormFactor", :value_required=>true},
{:name=>"skipRecordTypeSelect", :soap_type=>"boolean", :value_required=>true},
{:name=>"type", :picklist_values=>[], :soap_type=>"ActionOverrideType", :value_required=>true}
],
:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"actionOverrides",
:soap_type=>"ActionOverride", :value_required=>true
}

h.each do |k,v|
    p k
    p v
end