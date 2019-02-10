module Metadata
	class Deployer
	class << self

		def deploy(sforce_session, zip_file, options)
			Service::MetadataClientService.call(sforce_session).deploy(zip_file, options)
		end

		def check_deploy_status(sforce_session, id, include_details)
			Service::MetadataClientService.call(sforce_session).check_deploy_status(id, include_details)
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