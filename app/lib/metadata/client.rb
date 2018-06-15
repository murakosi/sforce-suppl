module Metadata
    class Client

        def initialize(options={})
            @headers = {}

            @wsdl = options[:wsdl]

            @headers = { 'tns:LocaleOptions' => { 'tns:language' => 'ja_JP' } }

            @version = options[:version] || Constants::DefaultApiVersion

            @logger = options[:logger] || false

            @log_level = options[:log_level] || :debug
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
                convert_response_tags_to: @response_tags,
                logger: @logger,
                log: (@logger != false),
                log_level: @log_level,
                endpoint: @server_url,
                pretty_print_xml: true,
                convert_request_keys_to: :lower_camelcase,
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
            #describe[:metadata_objects].map{|hash| hash[:xml_name] }.sort
            result = describe[:metadata_objects]
            xml_names = result.reject{|hash| hash[:xml_name] == "CustomLabels"}.map{|hash| hash[:xml_name]}
            children = result.select{|hash| hash.has_key?(:child_xml_names)}.map{|hash| hash[:child_xml_names]}
            Array[xml_names | children].flatten.sort
        end

        def read(type_name, full_name)
            call_metadata_api(:read_metadata, {:type_name => type_name, :full_name => full_name})
        end

        def update(type_name, metadata = {})           
            request_body = {:metadata => prepare_metadata(metadata), :attributes! => { :metadata => { 'xsi:type' => "tns:#{type_name}" }}}
            call_metadata_api(:update_metadata, request_body)
        end

        def prepare_metadata(metadata)
            metadata.values.map{|arr| arr.reject{|k, v| k == :"@xsi:type"}}
        end

        def retrieve(metadata_type, metadata)
            request_body = retrieve_request(metadata_type, metadata)
            call_metadata_api(:retrieve, request_body)
        end

        def retrieve_status(id, include_zip)
            request_body = {:id => id, :include_zip => include_zip}
            call_metadata_api(:check_retrieve_status, request_body)
        end

        def retrieve_request(metadata_type, metadata)
            {
                :retrieve_request => 
                {
                    :api_version=> @version,
                    :single_package => true,
                    :unpackaged => package(metadata_type, metadata)
                }
            }
        end

        def package(metadata_type, metadata)
            {:types => {:members => Array[metadata].compact.flatten, :name => metadata_type}}
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