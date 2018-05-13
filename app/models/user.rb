class User < ApplicationRecord

    has_secure_password validations: false

    def self.new_login_token
        SecureRandom.urlsafe_base64
    end

    def self.encrypt(token)
        Digest::SHA256.hexdigest(token.to_s)
    end

end