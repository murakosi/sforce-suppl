module Metadata
	module SessionController

	    def clear_session(metadata_type, type_info)
	        session[:metadata_type] = metadata_type
	        session[:metadata_type_info] = type_info
	        session[:read_result] = {}
	    end

	    def current_metadata_type
	        session[:metadata_type]
	    end

	    def current_metadata_field_types
	    	session[:metadata_type_info]
	    end

	    def raise_when_type_unmached(metadata_type)
	        if session[:metadata_type] != metadata_type
	            raise StandardError.new("Metadata type has been changed")
	        end
	    end

	    def try_save_session(metadata_type, full_name, result)
	        raise_when_type_unmached(metadata_type)
	        session[:read_result][full_name] = result
	    end

        def read_results
        	session[:read_result]
    	end
    	
    	def profile_list
    	    session[:profiles]
    	end
	end
end