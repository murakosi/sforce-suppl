module Metadata
    class Client

        def initialize(options={})
            @headers = {}

            @wsdl = options[:wsdl]

            @headers = { 'tns:LocaleOptions' => { 'tns:language' => 'ja_JP' } }

            @version = options[:version]

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
            @savon_options = {}
            %w(read_timeout open_timeout proxy raise_errors ssl_ca_cert_file).each do |prop|
                key = prop.to_sym
                @savon_options[key] = options[key] if options.key?(key)
            end
        end

        def login(options={})

            if options[:session_id] && options[:metadata_server_url]
                @session_id = options[:session_id]
                @server_url = options[:metadata_server_url]
            else
                raise ArgumentError.new("Must provide session_id/metadata_server_url.")
            end

            @headers = @headers.merge({"tns:SessionHeader" => {"tns:sessionId" => @session_id}})

            @client = Savon.client({
                wsdl: @wsdl,
                soap_header: @headers,
                convert_request_keys_to: :none,
                convert_response_tags_to: @response_tags,
                logger: @logger,
                log: (@logger != false),
                endpoint: @server_url,
                ssl_version: @ssl_version # Sets ssl_version for HTTPI adapter
            }.update(@savon_options))

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

        def describe
            call_metadata_api(:describe_metadata, {:api_version => @version})
        end

        def describe_metadata_objects
            describe[:metadata_objects].collect{|type| type[:xml_name] }.sort
        end

        def read(type_name, full_name)
            call_metadata_api(:read_metadata, {:type_name => type_name, :full_name => full_name})
        end

        def update(type,params)
            #type = type.to_s.camelize
            #aram = get_param(type, current_name, metadata)
            #params.store('@xsi:type', "#{type}")
            p params
            #call_metadata_api(:update_metadata, {:metadata => [params]})
            #call_metadata_api(:update_metadata, get_param(type, params))
        end
=begin
req2 = {:labels => {:full_name=>"test_label", :categories=>"category", :language=>"ja", :protected=>true,
:short_description=>"test label", :value=>"values are here"}}

b = {:metadata => [req2], :attributes! => { :metadata => { 'xsi:type' => "tns:CustomLabels" }}}

message_hash = b
response = meta.call(:update_metadata) do |locals|
    locals.message message_hash
end

=end
        def get_param(type, args)
            if args.has_key?("@xsi:type")
                args.delete("@xsi:type")
            end

            {
              :metadata => [args], :attributes! => { :metadata => {'xsi:type' => "tns:#{type}"}}          
            }
        end

        def call_metadata_api(method, message_hash={})
            response = @client.call(method.to_sym) do |locals|
                locals.message message_hash
            end

            # Convert SOAP XML to Hash
            response = response.to_hash

            # Get Response Body
            key = key_name("#{method}Response")
            response_body = response[key]

            # Grab result section if exists.
            result = response_body ? response_body[key_name(:result)] : nil
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