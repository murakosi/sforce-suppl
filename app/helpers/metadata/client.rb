require "hashie"
require "savon"
module Metadata
    class Client

    def initialize(options={})
      @describe_cache = {}
      @describe_layout_cache = {}
      @headers = {}

      @wsdl = "C:/VSCode/RubyProject/mrdk-sforce-suppl/resources/metadata.xml"

      # If a client_id is provided then it needs to be included
      # in the header for every request.  This allows ISV Partners
      # to make SOAP calls in Professional/Group Edition organizations.

      client_id = options[:client_id] || Soapforce.configuration.client_id
      @headers = { 'tns:CallOptions' => { 'tns:client' => client_id } } if client_id

      @version = options[:version] || Soapforce.configuration.version || 28.0
      #@host = options[:host] || 'login.salesforce.com'
      #@login_url = options[:login_url] || "https://#{@host}/services/Soap/u/#{@version}"

      @logger = options[:logger] || false
      # Due to SSLv3 POODLE vulnerabilty and disabling of TLSv1, use TLSv1_2
      @ssl_version = options[:ssl_version] || :TLSv1_2

      if options[:tag_style] == :raw
        @tag_style = :raw
        @response_tags = lambda { |key| key }
      else
        @tag_style = :snakecase
        @response_tags = lambda { |key| key.snakecase.to_sym }
      end

      # Override optional Savon attributes
      savon_options = {}
      %w(read_timeout open_timeout proxy raise_errors).each do |prop|
        key = prop.to_sym
        savon_options[key] = options[key] if options.key?(key)
      end

      @client = Savon.client({
        wsdl: @wsdl,
        soap_header: @headers,
        convert_request_keys_to: :none,
        convert_response_tags_to: @response_tags,
        pretty_print_xml: true,
        logger: @logger,
        log: (@logger != false),
        #endpoint: @login_url,
        ssl_version: @ssl_version # Sets ssl_version for HTTPI adapter
      }.update(savon_options))
    end

    def login(options={})
      result = nil
        if options[:session_id] && options[:metadata_server_url]
        @session_id = options[:session_id]
        @server_url = options[:metadata_server_url]
      else
        raise ArgumentError.new("Must provide session_id/metadata_server_url.")
      end

      @headers = @headers.merge({"tns:SessionHeader" => {"tns:sessionId" => @session_id}})

      @client = Savon.client(
        wsdl: @wsdl,
        soap_header: @headers,
        convert_request_keys_to: :none,
        convert_response_tags_to: @response_tags,
        logger: @logger,
        log: (@logger != false),
        endpoint: @server_url,
        ssl_version: @ssl_version # Sets ssl_version for HTTPI adapter
      )
    end
    alias_method :authenticate, :login

    # Public: Get the names of all wsdl operations.
    # List all available operations from the partner.wsdl
    def operations
      @client.operations
    end
    
    def list(*args)
        queries = args.map(&:to_s).map(&:camelize).map { |t| {:type => t} }
        call_metadata_api(:list_metadata, {:query => queries})
    end

    def describe()
      call_metadata_api(:describe_metadata, {:api_version => @version})
    end

    def metadata_objects
      describe[:metadata_objects].collect { |type| type[:xml_name] }.sort
    end

    def call_metadata_api(method, message_hash={})

      response = @client.call(method.to_sym) do |locals|
        locals.message message_hash
      end

      # Convert SOAP XML to Hash
      response = response.to_hash

      puts response
      # Get Response Body
      key = key_name("#{method}Response")
      response_body = response[key]

      # Grab result section if exists.
      result = response_body ? response_body[key_name(:result)] : nil

=begin
      # Raise error when response contains errors
      if result.is_a?(Hash)
        xsi_type = result[key_name(:"@xsi:type")].to_s

        if result[key_name(:success)] == false && result[key_name(:errors)]
          errors = result[key_name(:errors)]
          raise Savon::Error.new("#{errors[key_name(:status_code)]}: #{errors[key_name(:message)]}")
        elsif xsi_type.include?("sObject")
          result = SObject.new(result)
        elsif xsi_type.include?("QueryResult")
          result = QueryResult.new(result)
        else
          result = Result.new(result)
        end
      end
=end
      result
    end

    def method_missing(method, *args)
      call_metadata_api(method, *args)
    end

    def key_name(key)

      if @tag_style == :snakecase
        key.is_a?(Symbol) ? key : key.snakecase.to_sym
      else
        if key.to_s.include?('_')
          camel_key = key.to_s.gsub(/\_(\w{1})/) {|cap| cap[1].upcase }
        else
          key.to_s
        end
      end

    end

  end
end
