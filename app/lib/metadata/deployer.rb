module Metadata
	class Deployer
	class << self

		def deploy(zip_file, options)
		end
		#checkDeployStatus(ID id, includeDetails boolean);

		def deploy_options
			{
				:checkOnly => true,
				:ignoreWarnings => false,
				:purgeOnDelete => false,
				:rollbackOnError => false,
				:singlePackage => false
			}
		end

		def check_deploy_status(id, include_details)

		end
	end
	end
end