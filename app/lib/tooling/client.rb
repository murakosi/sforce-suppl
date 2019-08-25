require "savon"

module Tooling
    class Client

        def initialize(options={})
            @headers = {}

            @wsdl = options[:wsdl]

            if options[:debug_categories].nil?
                debug_categories = [ {:category => "All", :level => "NONE"}]
            else
                debug_categories = options[:debug_categories]
            end

            #Set debug info
            @headers = {"tns:DebuggingHeader" => {"tns:categories" => debug_categories}}

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

            if options[:session_id] && options[:server_url]
                @session_id = options[:session_id]
                @server_url = options[:server_url].gsub(/Soap\/.*\/.*/, "Soap/T/" + @version)
            else
                raise ArgumentError.new("Must provide session_id/server_url.")
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

        def operations
            @client.operations
        end
        
        def namespace
            @client.wsdl.namespace
        end

        def response_header
            @response_header
        end

        def query(soql)
            call_tooling_api(:query, {:queryString => soql})
        end
        
        def execute_anonymous(code)
            result = call_tooling_api(:execute_anonymous, {:string => code})
            if @response_header.present?
                {
                    :debug_log => @response_header[:debugging_info][:debug_log],
                    :anonymous_result => result
                }
            else
                {
                    :debug_log => "",
                    :anonymous_result => result
                }
            end
        end

        def call_tooling_api(method, message_hash={})          

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
            call_tooling_api(method, *args)
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
