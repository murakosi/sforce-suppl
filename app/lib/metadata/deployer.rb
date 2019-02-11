module Metadata
	class Deployer
	class << self
		include Generator::TreeNodeGenerator

		def deploy(sforce_session, zip_file, options)
			Service::MetadataClientService.call(sforce_session).deploy(zip_file, options)
		end

		def check_deploy_status(sforce_session, id, include_details)
			deploy_result = Service::MetadataClientService.call(sforce_session).check_deploy_status(id, include_details)
			#result = deploy_result.except(:details)
			column_options = []
			#result.keys.size.times{column_options << {type: "text", readOnly: true}}
			{
				:id => deploy_result[:id],
				:done => deploy_result[:done],
				#:result => {:columns => result.keys.map{|key| key.to_s}, :rows => [result.values.map{|val| val.to_s}], :column_options => column_options},
				:result => parse_read_result(deploy_result, "#")
				#:details => deploy_result[:details]				
			}			

		end

		def deploy_options
			{
				:checkOnly => true,
				:ignoreWarnings => false,
				:purgeOnDelete => false,
				:rollbackOnError => false,
				:singlePackage => false
			}
		end
	end
	end
end