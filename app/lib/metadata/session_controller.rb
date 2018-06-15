module Metadata
	module SessionController
	    def clear_session(metadata_type)
	        session[:metadata_type] = metadata_type
	        session[:read_result] = {}
	    end

	    def current_metadata_type
	        session[:metadata_type]
	    end

	    def raise_when_type_unmached(metadata_type)
	        if session[:metadata_type] != metadata_type
	            raise StandardError.new("Metadata type has been changed")
	        end
	    end

	    def try_save_session(metadata_type, full_name, result)
	        raise_when_type_unmached(metadata_type)

	        if session[:read_result].present? && session[:read_result].values.size >= Max_metadata_count
	            raise StandardError.new("Cannot read/edit more than #{Max_metadata_count} meatadata all at once")
	        end

	        session[:read_result][full_name] = result
	    end

        def read_results
        	session[:read_result]
    	end
	end
end