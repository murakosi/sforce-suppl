module Sforceutils
    class SforceClient
    #class << self

        def initialize(session_manager)
            @session_manager = session_manager
        end

        def sforce_session_alive?
            begin
                sforce_soap_client()
                return true
            rescue StandardError => ex
                return false
            end            
        end

        def sforce_soap_client
            client = Soapforce::Client.new
            client.authenticate(@session_manager.sforce_session)
            client            
        end

        def sforce_metadata_client
            client = Metadata::Client.new
            client.authenticate(@session_manager.sforce_metadata_session)
            client               
        end
    #end
    end
end