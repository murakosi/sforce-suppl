module Utils
	class SforceApiUtils
		class << self

	        def sforce_host(sforce_session)
	            if is_sandbox?(sforce_session)
	                host = Constants::SandboxUrl
	            else
	                host = Constants::ProductionUrl
	            end
	        end

	        def is_sandbox?(sforce_session)
	            ActiveRecord::Type::Boolean.new.cast(sforce_session[:sandbox])
	        end

	        def ssl_certificate
	        	if Rails.env.production?
	        		return nil
	        	end
	        	
	            cert_file = File.expand_path("./lib/cacert.cer", Rails.root)

	            if File.exist?(cert_file)
	                cert_file
	            else
	                nil
	            end
	        end

		end
	end
end