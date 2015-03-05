# -*- encoding: utf-8 -*-
# stub: brakeman 2.4.3 ruby lib

Gem::Specification.new do |s|
  s.name = "brakeman"
  s.version = "2.4.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Justin Collins"]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDLjCCAhagAwIBAgIBADANBgkqhkiG9w0BAQUFADA9MQwwCgYDVQQDDANnZW0x\nGDAWBgoJkiaJk/IsZAEZFghicmFrZW1hbjETMBEGCgmSJomT8ixkARkWA29yZzAe\nFw0xMzEyMTIwMDMxNTdaFw0xNDEyMTIwMDMxNTdaMD0xDDAKBgNVBAMMA2dlbTEY\nMBYGCgmSJomT8ixkARkWCGJyYWtlbWFuMRMwEQYKCZImiZPyLGQBGRYDb3JnMIIB\nIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxCHmXCaAcZ4bVjijKoyQFx4N\ndyN7B7bqY8wOXy6f/UZ6mdC8IRAj82KaWQjNE2LT/ObFUWpCRyLdrwjkDjdFDyOT\nmZCZkiOeEy2ZxYGfxXMI/xg24c8r5Xmh16ErsYuprRcg+/KZ6s4UjseBNTARmBK4\nIHcqIdnoWbYa3BWHoflJPaJUIaU+/yTclzFQHpswU7ka8ftIAWeoDQo22gasP/4N\nHtJvAIyg1DcWPLcn0qbZmdehg8HZv8C+2MuLKX/2qZG9eseegMqMlHHabwwEy9Vv\nf/t/+ltLjC0CRa2TqZ2EuQ5EEzbOsqAftaZJFmwv9Ut1UhjmdvR5RfN6dWMQ5QID\nAQABozkwNzALBgNVHQ8EBAMCBLAwHQYDVR0OBBYEFPyEKeRy09i8qSr+9KFbeTqw\nkMCSMAkGA1UdEwQCMAAwDQYJKoZIhvcNAQEFBQADggEBALEk8/Wnl2VAqchxWlbg\nRN0MkVUWMf8L0xxUiVKo5QeL4NBViALMBrU6IS4y6zyn+FoULAMEawUjZlZf4Hcg\nS9unev3p+RTWUyksAnA27wHZs/NRIkW34s1ZI5NNE/xyu4ULOQjfh1wOjlWzyHu9\n0t41/CtpgNPM2uAjG3RIqlp7QKXlby50cQqWJQCgTH3JNjMhmROEhTsI6COoApvd\nCe7Br39yjeoarvekq0wCXBYakUBw/DdZCG7mFZ6xgh01eqnZUsNd8vM+6V6v23Vu\njk2tMjFT4L1dA3MEsz3+MP144PDhPCh7tPe6yy81BOvyYTVkKzrAkgKwHD1CuvsH\nbdw=\n-----END CERTIFICATE-----\n"]
  s.date = "2014-03-23"
  s.description = "Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis."
  s.email = "gem@brakeman.org"
  s.executables = ["brakeman"]
  s.files = ["bin/brakeman"]
  s.homepage = "http://brakemanscanner.org"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Security vulnerability scanner for Ruby on Rails."

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby_parser>, ["~> 3.4.0"])
      s.add_runtime_dependency(%q<ruby2ruby>, ["~> 2.0.5"])
      s.add_runtime_dependency(%q<terminal-table>, ["~> 1.4"])
      s.add_runtime_dependency(%q<fastercsv>, ["~> 1.5"])
      s.add_runtime_dependency(%q<highline>, ["~> 1.6.20"])
      s.add_runtime_dependency(%q<erubis>, ["~> 2.6"])
      s.add_runtime_dependency(%q<haml>, ["< 5.0", ">= 3.0"])
      s.add_runtime_dependency(%q<sass>, ["~> 3.0"])
      s.add_runtime_dependency(%q<slim>, ["< 3.0", ">= 1.3.6"])
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.2"])
    else
      s.add_dependency(%q<ruby_parser>, ["~> 3.4.0"])
      s.add_dependency(%q<ruby2ruby>, ["~> 2.0.5"])
      s.add_dependency(%q<terminal-table>, ["~> 1.4"])
      s.add_dependency(%q<fastercsv>, ["~> 1.5"])
      s.add_dependency(%q<highline>, ["~> 1.6.20"])
      s.add_dependency(%q<erubis>, ["~> 2.6"])
      s.add_dependency(%q<haml>, ["< 5.0", ">= 3.0"])
      s.add_dependency(%q<sass>, ["~> 3.0"])
      s.add_dependency(%q<slim>, ["< 3.0", ">= 1.3.6"])
      s.add_dependency(%q<multi_json>, ["~> 1.2"])
    end
  else
    s.add_dependency(%q<ruby_parser>, ["~> 3.4.0"])
    s.add_dependency(%q<ruby2ruby>, ["~> 2.0.5"])
    s.add_dependency(%q<terminal-table>, ["~> 1.4"])
    s.add_dependency(%q<fastercsv>, ["~> 1.5"])
    s.add_dependency(%q<highline>, ["~> 1.6.20"])
    s.add_dependency(%q<erubis>, ["~> 2.6"])
    s.add_dependency(%q<haml>, ["< 5.0", ">= 3.0"])
    s.add_dependency(%q<sass>, ["~> 3.0"])
    s.add_dependency(%q<slim>, ["< 3.0", ">= 1.3.6"])
    s.add_dependency(%q<multi_json>, ["~> 1.2"])
  end
end
