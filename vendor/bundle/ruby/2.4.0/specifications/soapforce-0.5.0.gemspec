# -*- encoding: utf-8 -*-
# stub: soapforce 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "soapforce".freeze
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Joe Heth".freeze]
  s.date = "2016-03-04"
  s.description = "A ruby client for the Salesforce SOAP API based on Savon.".freeze
  s.email = ["joeheth@gmail.com".freeze]
  s.homepage = "https://github.com/TinderBox/soapforce".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Wraps Savon with helper methods and custom types for interacting with the Salesforce SOAP API.".freeze

  s.installed_by_version = "2.7.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<savon>.freeze, ["< 3.0.0", ">= 2.3.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["< 4.0.0", ">= 2.14.0"])
      s.add_development_dependency(%q<webmock>.freeze, ["< 2.0.0", ">= 1.17.0"])
      s.add_development_dependency(%q<simplecov>.freeze, ["< 1.0.0", ">= 0.9.0"])
    else
      s.add_dependency(%q<savon>.freeze, ["< 3.0.0", ">= 2.3.0"])
      s.add_dependency(%q<rspec>.freeze, ["< 4.0.0", ">= 2.14.0"])
      s.add_dependency(%q<webmock>.freeze, ["< 2.0.0", ">= 1.17.0"])
      s.add_dependency(%q<simplecov>.freeze, ["< 1.0.0", ">= 0.9.0"])
    end
  else
    s.add_dependency(%q<savon>.freeze, ["< 3.0.0", ">= 2.3.0"])
    s.add_dependency(%q<rspec>.freeze, ["< 4.0.0", ">= 2.14.0"])
    s.add_dependency(%q<webmock>.freeze, ["< 2.0.0", ">= 1.17.0"])
    s.add_dependency(%q<simplecov>.freeze, ["< 1.0.0", ">= 0.9.0"])
  end
end
