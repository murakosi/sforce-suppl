require "./flatter"

h = [{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"active", :soap_type=>"Boolean", :value_required=>false}, {:is_foreign_key=>false, :is_name_field=>true, :min_occurs=>"0", :name=>"fullName", :soap_type=>"string", :value_required=>true}, {:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"assignedTo", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"booleanFilter", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"businessHours", :soap_type=>"string", :value_required=>true}, {:fields=>[{:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"1", :name=>"field", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"value", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"valueField", :soap_type=>"string", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"criteriaItems", :soap_type=>"FilterItem", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"disableEscalationWhenModified", :soap_type=>"boolean", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"formula", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"notifyCcRecipients", :soap_type=>"boolean", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"overrideExistingTeams", :soap_type=>"boolean", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"replyToEmail", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"senderEmail", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"senderName", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"team", :soap_type=>"string", :value_required=>true}, {:is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"template", :soap_type=>"string", :value_required=>true}], :is_foreign_key=>false, :is_name_field=>false, :min_occurs=>"0", :name=>"ruleEntry", :soap_type=>"RuleEntry", :value_required=>true}]

s = [
{:a => :b},
{:b => [:b1,:b2, :c]},
{:b1 => nil},
{:b2 => "b"},
{:c => [:c1,:c2]},
{:c1 => "dfa"},
{:c2 => "c"}
]

co = []
s.each do |ss|
    ss.each do |k,v|
        if ss.has_key?(v)
        else
            
        end
    end
end

=begin
f = nil
h.each do |h2|
    f = Flatter.flat(h2)
end
f.each do |f2|
    p f2
end

=end

=begin
h.each do |a|
    if a.has_key?(:fields)
        a.each do |b|
            x = Hash[*b]
            if x.has_key?(:fields)
                b.each do |c|
                    p c
                end
            end
        end
    end
end

<% content_for :header_tags do %>
    <%= stylesheet_link_tag 'estimate', :plugin => 'estimate_premise' %>
    <%= stylesheet_link_tag 'handsontable.full.min', :plugin => 'estimate_premise' %>
    <%= stylesheet_link_tag 'bootstrap', :plugin => 'estimate_premise' %>
<% end %>

=end
