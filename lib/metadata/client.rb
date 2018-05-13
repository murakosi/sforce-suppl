module Metadata
    class Client
        Metadata_namespace = "{http://soap.sforce.com/2006/04/metadata}"

        def initialize(options={})
            @describe_cache = {}
            @describe_layout_cache = {}
            @headers = {}

            @wsdl = File.expand_path("./resources/metadata.xml")

            # If a client_id is provided then it needs to be included
            # in the header for every request.  This allows ISV Partners
            # to make SOAP calls in Professional/Group Edition organizations.

            client_id = options[:client_id] || Soapforce.configuration.client_id
            @headers = { 'tns:LocaleOptions' => { 'tns:language' => 'ja' } }

            @version = options[:version] || Soapforce.configuration.version || 41.0#28.0

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

        def describe
            call_metadata_api(:describe_metadata, {:api_version => @version})
        end

        def describe_metadata_objects
            describe[:metadata_objects].collect{|type| type[:xml_name] }.sort
        end

        def read(type_name, full_name)
            call_metadata_api(:read_metadata, {:type_name => type_name, :full_name => full_name})
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