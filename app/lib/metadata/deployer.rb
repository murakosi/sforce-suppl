module Metadata
	class Deployer
	class << self
		include Generator::TreeNodeGenerator

		Key_order = %i[id done status success error_message error_status_code details number_component_errors number_components_deployed number_components_total created_date start_date completed_date last_modified_date created_by created_by_name check_only ignore_warnings rollback_on_error]
		Exclude_header = %i[canceled_by canceld_by_name state_detail run_tests_enabled number_test_errors number_tests_completed number_tests_total]

		def deploy(sforce_session, zip_file, options)
			Service::MetadataClientService.call(sforce_session).deploy(zip_file, options)
		end

		def check_deploy_status(sforce_session, id, include_details)
			deploy_result = Service::MetadataClientService.call(sforce_session).check_deploy_status(id, include_details)
			result = deploy_result.except(*Exclude_header).slice(*Key_order)
			
			{
				:id => deploy_result[:id],
				:done => deploy_result[:done],
				:result => generate_nodes_from_hash(result, "#")
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