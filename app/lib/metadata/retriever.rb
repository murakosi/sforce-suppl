require "fileutils"
require "zip"

module Metadata
	class Retriever
	class << self


		def retrieve(sforce_session, metadata_type, metadata)
			start_retrieve(sforce_session, metadata_type, metadata)
			
			#task = Thread.new(&execute_retrieve)

			#task.join

			#retrieve_result
		end

		def start_retrieve(sforce_session, metadata_type, metadata)
			@status = nil
			@client = Service::MetadataClientService.call(sforce_session)
			response = @client.retrieve(metadata_type, metadata)
			@id = response[:id]
			@metadata_type = metadata_type
			{:id => response[:id], :done => false}
		end

		def execute_retrieve
			proc {				
		        loop do
			    	sleep (1)

			    	response = check_status

			    	if succeeded? || failed?
			    		break
			      	end
		        end
		    }
		end

		#def check_status
		def retrieve_status
			response = @client.retrieve_status(@id, false)
			@status = response[:status]
			#response
			
			{:id => response[:id], :done => response[:done]}
		end

		def succeeded?
			@status == "Succeeded"
		end

		def failed?
			@status == "Failed"
		end
		
		def retrieve_result
			if succeeded?
				succeeded_result
			else
				raise StandardError.new(failed_result)
			end
		end

		def succeeded_result
			response = @client.retrieve_status(@id, true)
			{
				:zip_file => decode(response[:zip_file]),
				:id => @metadata_type
			}
		end

		def failed_result
			response = @client.retrieve_status(@id, false)
			response[:error_message]
		end

		def decode(zip_file)
			Base64.decode64(zip_file)
		end
	end
	end
end