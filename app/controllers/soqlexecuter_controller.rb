require 'soapforce'
require 'exceptions'

class SoqlexecuterController < ApplicationController
  before_action :require_sign_in!
  
  protect_from_forgery :except => [:show]
  
  Exclude_key_names = ["@xsi:type", "type"]
  
  def new
    prepare
  end

  def prepare
    @object_name = String.new
    
    @header_array = Array.new
    @records = Hash.new
    @raw = String.new
    @client = Soapforce::Client.new
  end
  
  def index
    prepare    
  end

  def show
    puts "param:" + params[:soql]
    execute_soql()

  end

  def execute_soql()

    begin
      getRecords(params[:soql])
      #raise StandardError.new("unexpected token: procure__c\nthis is")
      puts @records
      render :json => @records, :status => 200
    rescue StandardError => ex
      render :json => {:error => ex.message}, :status => 400
    end

  end

  def getRecords(soql)
    #prepare
    getclient

    qresult = @client.query(soql)

    if qresult.empty?
       #@records = [Hash.new]
       #return
       raise Exceptions::NoMatchedRecordError.new("No matched records found")
    end

    @records = qresult.records.map{ |record| record.to_h }
                              .map{ |hash| 
                                    hash.select{ |k,v| !Exclude_key_names.include?(k.to_s)}
                                        .reject{ |k,v| k.to_s == "id" && v.nil?}
                                  }
  end

  def parse_exception(ex)

  end

  def getclient
    @client = Soapforce::Client.new
    @client.authenticate(username: "murakoshi@cse.co.jp", password: "s13926cse")
  end

end
