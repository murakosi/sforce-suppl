module Describe
    class DescribeResults
    	class << self

	    	def field_result
	    		if @field_result.present?
	    			@field_result
	    		else
	    			@field_result = {}
	    		end
	    	end

	    	def global_result
	    		if @global_result.present?
	    			@global_result
	    		else
	    			@global_result = []
	    		end
	    	end

	    	def global_result=(value)
	    		@global_result = value
	    	end

	    	def formatted_field_result
	    		if @formatted_field_result.present?
	    			@formatted_field_result
	    		else
	    			@formatted_field_result = {}
	    		end
	    	end

    	end
    end
end