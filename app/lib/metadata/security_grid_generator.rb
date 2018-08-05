module Metadata
	class SecurityGridGenerator
	class << slef

		def security_grid(profile_result, custom_fields)
			profiles = profile_list.map{|h| h[:full_name]}
			fields = custom_fields.map{|h| h[:full_name]}
			permissions = profile_list
			{
				:security_cols => profiles,
				:security_rows => fields,
			}
		end
	end
	end
end