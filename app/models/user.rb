class User < ApplicationRecord

  #attr_accessor :name, :password, :login_token

    #def new(attributes = {})
    #    puts attributes
    #    @name  = attributes[:name]
    #    @password = attributes[:password]
    #end

    def self.new_login_token
      SecureRandom.urlsafe_base64
    end

    def self.encrypt(token)
      Digest::SHA256.hexdigest(token.to_s)
    end

end
