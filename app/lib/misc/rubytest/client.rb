class Client
class << self

        def call_metadata_api(client, method, message_hash={})
            response = client.call(method.to_sym) do |locals|
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

        def key_name(key)
                key.is_a?(Symbol) ? key : key.snakecase.to_sym
        end
end
end