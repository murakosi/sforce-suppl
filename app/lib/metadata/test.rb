require "hashie"
require "yaml"

source = {:full_name=>"CustomLabels", :labels=>[{:full_name=>"CNH", :language=>"ja", :protected=>{:one => true, :two => true}, :short_description=>"CNH", :value=>"lista"}, {:full_name=>"test_label", :categories=>"category", :language=>"ja", :protected=>true, :short_description=>"test label", :value=>"values are here"}], :"@xsi:type"=>"CustomLabels"}
s2 = {:labels=>{:full_name=>"abc", :language=>"ja", :protected=>true, :short_description=>"CNH", :value=>"lista"}}

#p source.merge(s2)
path = "labels/0/full_name"
path = "labels[0].protected.two"
value = false

path = "m." + path + "=" + value.to_s
m = Hashie::Mash.new(source)
p m
eval(path)
p m
p m.to_hash
#p m
#p m.labels[0].protected.two
#str = "m.labels[0].protected.two = false"
#p eval(str)

#p m
=begin
in_source = nil
abc = {}
path.split("/").each do | el |
	if el == "0"
		if in_source.nil?
			in_source = source[el.to_i]
		else
			in_source = in_source[el.to_i]
		end
	else
		if in_source.nil?
			in_source = source[el.to_sym]
		else
			in_source = {el.to_sym => in_source[el.to_sym]}
		end
	end
	if in_source.is_a?(Hash)
		abc.merge!(in_source)
	end
end
ls = in_source.merge(uph)
p ls
abc.merge!(ls)
p abc
=end