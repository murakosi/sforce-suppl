hash = {:activateable=>false,
     :child_relationships=>[
         {:cascade_delete=>true,
            :child_s_object=>"Attachment",
             :deprecated_and_hidden=>false, 
             :field=>"ParentId",
             :relationship_name=>"Attachments"
            },
             {:cascade_delete=>true, 
                :child_s_object=>"ContentDocumentLink",
                 :deprecated_and_hidden=>false,
                  :field=>"LinkedEntityId",
                   :relationship_name=>"ContentDocumentLinks"
                }
                   ], :createable=>true, :custom=>true, :custom_setting=>false, :deletable=>true, :deprecated_and_hidden=>false, :feed_enabled=>true, :fields=>[{:auto_number=>false, :byte_length=>"18", :calculated=>false, :case_sensitive=>false},{:auto_number=>false, :byte_length=>"18", :calculated=>false, :case_sensitive=>false}]}
hash.each{|k,v| puts "key:" + k.to_s + " val:" + v.to_s}
h2 = hash[:fields]
puts "---------------------"
h2.each{|k,v| puts "key:" + k.to_s + " val:" + v.to_s}
puts "------------------------"
puts h2.first.keys
puts h2.each{ |hash| hash.values}
