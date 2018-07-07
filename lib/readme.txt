Soapforce::Client uses Savon client.
But Soapforce::Client does not allow "ssl_ca_cert_file" Savon option and it does not maintain any of Savon options
 that it uses in its initialization.
It seems required to specify "ssl_ca_cert_file" to call Salesforce Soap API using Session ID in Sandbox.
Thus Soapforce::Client needs modifications so that it accepts "ssl_ca_cert_file" option and uses the option
 anytime its login method is called.