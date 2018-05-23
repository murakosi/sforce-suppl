class User < ApplicationRecord

    has_secure_password validations: false

    secret_key = ENV['DB_US_COLUMN_KEY']
    attr_encrypted :sforce_session_id, :key => secret_key
    attr_encrypted :sforce_server_url, :key => secret_key
    attr_encrypted :sforce_metadata_server_url, :key => secret_key

    def self.new_login_token
        SecureRandom.urlsafe_base64
    end

    def self.encrypt_token(token)
        Digest::SHA256.hexdigest(token.to_s)
    end

end