module Sforceutils
    class SforceClient
    #class << self
        Production_url = "login.salesforce.com"
        Sandbox_url = "test.salesforce.com"

        def initialize(session_manager)
            @session_manager = session_manager
        end

        def login(login_params)
            if is_sandbox?(login_params)
                host = Sandbox_url
            else
                host = Production_url
            end

            client = Soapforce::Client.new
            client.authenticate(:username => login_params[:name], :password => login_params[:password], :host => host)
        end

        def logout
            soap_client.logout()
        end

        def sforce_session_alive?
            begin
                soap_client()
                return true
            rescue StandardError => ex
                return false
            end            
        end

        def soap
            client = Soapforce::Client.new
            client.authenticate(@session_manager.sforce_session)
            client            
        end

        def metadata
            client = Metadata::Client.new
            client.authenticate(@session_manager.sforce_metadata_session)
            client               
        end

        private
            def is_sandbox?(login_params)
                ActiveRecord::Type::Boolean.new.cast(login_params[:is_sandbox])
            end
    #end
    end
end