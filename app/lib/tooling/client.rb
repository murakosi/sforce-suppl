require "savon"
require "base64"

module Tooling
    class Client

        def initialize(options={})
            @headers = {}

            @wsdl = options[:wsdl]

            @headers = {}#{ 'tns:LocaleOptions' => { 'tns:language' => 'ja_JP' } }

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
                @server_url = options[:server_url]
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
                #element_form_default: :unqualified,
                ssl_version: @ssl_version # Sets ssl_version for HTTPI adapter
            }.update(@savon_options))
        end
        alias_method :authenticate, :login

        # Public: Get the names of all wsdl operations.
        # List all available operations from the partner.wsdl
        def operations
            @client.operations
        end
        
        def namespace
            @client.wsdl.namespace
        end

        def execute_anonymous(code)
            #call_tooling_api(:execute_anonymous, {:executeAnonymousRequest => { :string => Base64.urlsafe_encode64(code)} })
            #@client.call(:execute_anonymous)
            call_tooling_api(:execute_anonymous, {})
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