class SforceClient < ApplicationRecord

    @client = Soapforce::Client.new

    def self.authenticate(param)
        @client.authenticate(username: param[:name], password: param[:password])
    end

    def self.client
        @client
    end

    def self.logout
        @client.logout
    end

    def self.finalize
        @client = nil
    end
end