module Metadata
	class Deployer
	class << self
		include Metadata::TreeNodeBuilder

		Key_order = %i[id done status success error_message error_status_code details 
			number_component_errors number_components_deployed number_components_total 
			created_date start_date completed_date last_modified_date created_by 
			created_by_name check_only ignore_warnings rollback_on_error]
			
		Exclude_header = %i[canceled_by canceld_by_name state_detail run_tests_enabled number_test_errors number_tests_completed number_tests_total]

		def deploy(sforce_session, zip_file, options)
			@client = Service::MetadataClientService.call(sforce_session)
			async_result = @client.deploy(zip_file, options)
			@id = async_result[:id]
			async_result
		end

		def check_deploy_status(include_details)
			deploy_result = @client.check_deploy_status(@id, include_details)
			result = deploy_result.except(*Exclude_header).slice(*Key_order)
			
			{
				:id => deploy_result[:id],
				:done => deploy_result[:done],
				:result => build_tree_nodes_from_hash(result, "#")
			}			

		end

		def default_deploy_options
			{
				:CheckOnly => true,
				:IgnoreWarnings => false,
				:PurgeOnDelete => false,
				:RollbackOnError => false,
				:SinglePackage => false
			}
		end
	end
	end
end