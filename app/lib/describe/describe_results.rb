#require "singleton"

module Describe
    class DescribeResults
    	#include ActiveModel::Model
    	class << self

        #attr_accessor :global_result
        #attr_accessor :field_result
        #attr_accessor :formatted_field_result

    	def initialize
    		@global_result = []
    		@field_result = {}
    		@formatted_field_result = {}
    	end

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