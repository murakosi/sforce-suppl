require 'fileutils'

class DescriberController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery :except => [:execute]

  def show
  end

  def execute
    doit()

    @input_error = String.new

    method = params[:method].to_sym
    args = params[:args]

    if method.empty? || args.empty?
      @input_error = "input error"  
      render "show"
      return
    end
    method = "describe_global"
    begin

      tmp = current_client.list_sobjects
      puts "ok"
      if tmp.kind_of?(Array)
          @result = {:method => method, :columns => ["Name"], :rows => tmp.map{|v| {"name" => v}}} 
      elsif tmp.kind_of?(Soapforce::Result)
        t2 = tmp[:fields]
        @result = {:method => method, :columns => t2.first.keys, :rows => t2.each{ |hash| hash.values}}
      else
        raise StandardError.new("error:" + tmp.to_s)
      end
      render :json => @result, :status => 200
    rescue StandardError => ex
      puts "error"
      puts ex.message
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def doit
    src_path = "./lib/assets/book1.xlsx"

    dest = "./Output/book1_copy.xlsx"

    FileUtils.cp(src_path, dest)
    #@workbook = RubyXL::Parser.parse("file.xlsx")
  end
end
