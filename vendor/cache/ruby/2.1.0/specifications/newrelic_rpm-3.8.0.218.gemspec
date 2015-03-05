# -*- encoding: utf-8 -*-
# stub: newrelic_rpm 3.8.0.218 ruby lib

Gem::Specification.new do |s|
  s.name = "newrelic_rpm"
  s.version = "3.8.0.218"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jason Clark", "Sam Goldstein", "Jonan Scheffler", "Ben Weintraub", "Chris Pine"]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDODCCAiCgAwIBAgIBADANBgkqhkiG9w0BAQUFADBCMREwDwYDVQQDDAhzZWN1\ncml0eTEYMBYGCgmSJomT8ixkARkWCG5ld3JlbGljMRMwEQYKCZImiZPyLGQBGRYD\nY29tMB4XDTE0MDIxMjIzMzUzMloXDTE1MDIxMjIzMzUzMlowQjERMA8GA1UEAwwI\nc2VjdXJpdHkxGDAWBgoJkiaJk/IsZAEZFghuZXdyZWxpYzETMBEGCgmSJomT8ixk\nARkWA2NvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANxaTfJVp22V\nJCFhQTS0Zuyo66ZknUwwoVbhuSoXJ0mo9PZSifiIwr9aHmM9dpSztUamDvXesLpP\n8HESyhe3sgpK0z7UXbDmtWZZx43qulx3xTObLQauVZcxP8qqGqvRzdovqXnFe8lN\nsRUnXQjm9kArMI8uHhcU7XvlbQeTtPcjP0U/ZSyKABsJXRamQ/SVCPXqAHXv+OWP\nt4yDB/MrAQFVSoNisyYtB7Af/izqw0/cnUCAOXGQL24l4Ir0dwMd0K6oAnaG93DB\nv6yb30VT5elw40BeIhBsjZP731vRgXIlIKYwhVAlkvRkexAy9kH456Vt0fDBBYka\neE53BhdcguUCAwEAAaM5MDcwCQYDVR0TBAIwADAdBgNVHQ4EFgQUPJxv/VCFdHOH\nlINeV2xQGQhFthEwCwYDVR0PBAQDAgSwMA0GCSqGSIb3DQEBBQUAA4IBAQDRCiPq\n50B4sJN0Gj2T+9g+uXtC845mJD+0BlsAVjLcc+TchxxD3BYeln9c2ErPSIrzZ92Q\nYlwLvw99ksJ5Qa/tAJCUyE3u9JuldalewRi/FHjoGcdhjUErzIyHtNlnCbTMfScz\n5T+r8iUhvt0tcZ0/dQ1LFN8vMizN4Rm6JMXsmkHHxuosllQ9Q14sCYd2ekk2UF0l\n59Jd6iWx3iVmUHSQNXiAdEihcwcx3e71dBNzl6FiR328PzniUjrhoSKzVLQv+JlR\n1fUxkomKs2EL+FYMwnAb+VmNOhv1S+sJhbjZ30PKgz6vLhT6unieCjLk9wGGmlSK\nYjbnvA9qraLLajSj\n-----END CERTIFICATE-----\n"]
  s.date = "2014-04-22"
  s.description = "New Relic is a performance management system, developed by New Relic,\nInc (http://www.newrelic.com).  New Relic provides you with deep\ninformation about the performance of your web application as it runs\nin production. The New Relic Ruby Agent is dual-purposed as a either a\nGem or plugin, hosted on\nhttp://github.com/newrelic/rpm/\n"
  s.email = "support@newrelic.com"
  s.executables = ["mongrel_rpm", "newrelic_cmd", "newrelic", "nrdebug"]
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.md", "GUIDELINES_FOR_CONTRIBUTING.md", "newrelic.yml"]
  s.files = ["CHANGELOG", "GUIDELINES_FOR_CONTRIBUTING.md", "LICENSE", "README.md", "bin/mongrel_rpm", "bin/newrelic", "bin/newrelic_cmd", "bin/nrdebug", "newrelic.yml"]
  s.homepage = "http://www.github.com/newrelic/rpm"
  s.licenses = ["New Relic", "MIT", "Ruby"]
  s.post_install_message = "# New Relic Ruby Agent Release Notes #\n\n## v3.8.0 ##\n\n* Better support for forking and daemonizing dispatchers (e.g. Puma, Unicorn)\n\n  The agent should now work out-of-the box with no special configuration on\n  servers that fork or daemonize themselves (such as Unicorn or Puma in some\n  configurations). The agent's background thread will be automatically restarted\n  after the first transaction processed within each child process.\n\n  This change means it's no longer necessary to set the\n  'restart_thread_in_children setting' in your agent configuration file if you\n  were doing so previously.\n\n* Rails 4.1 support\n\n  Rails 4.1 has shipped, and the Ruby agent is ready for it! We've been running\n  our test suites against the release candidates with no significant issues, so\n  we're happy to announce full compatibility with this new release of Rails.\n\n* Ruby VM measurements\n\n  The Ruby agent now records more detailed information about the performance and\n  behavior of the Ruby VM, mainly focused around Ruby's garbage collector. This\n  information is exposed on the new 'Ruby VM' tab in the UI. For details about\n  what is recorded, see:\n\n  http://docs.newrelic.com/docs/ruby/ruby-vm-stats\n\n* Separate in-transaction GC timings for web and background processes\n\n  Previously, an application with GC instrumentation enabled, and both web and\n  background processes reporting in to it would show an overly inflated GC band\n  on the application overview graph, because data from both web and non-web\n  transactions would be included. This has been fixed, and GC time during web\n  and non-web transactions is now tracked separately.\n\n* More accurate GC measurements on multi-threaded web servers\n\n  The agent could previously have reported inaccurate GC times on multi-threaded\n  web servers such as Puma. It will now correctly report GC timings in\n  multi-threaded contexts.\n\n* Improved ActiveMerchant instrumentation\n\n  The agent will now trace the store, unstore, and update methods on\n  ActiveMerchant gateways. In addition, a bug preventing ActiveMerchant\n  instrumentation from working on Ruby 1.9+ has been fixed.\n\n  Thanks to Troex Nevelin for the contribution!\n\n* More robust Real User Monitoring script injection with charset meta tags\n\n  Previous versions of the agent with Real User Monitoring enabled could have\n  injected JavaScript code into the page above a charset meta tag. By the HTML5\n  spec, the charset tag must appear in the first 1024 bytes of the page, so the\n  Ruby agent will now attempt to inject RUM script after a charset tag, if one\n  is present.\n\n* More robust connection sequence with New Relic servers\n\n  A rare bug that could cause the agent's initial connection handshake with\n  New Relic servers to silently fail has been fixed, and better logging has been\n  added to the related code path to ease diagnosis of any future issues.\n\n* Prevent over-counting of queue time with nested transactions\n\n  When using add_transaction_tracer on methods called from within a Rails or\n  Sinatra action, it was previously possible to get inflated queue time\n  measurements, because queue time would be recorded for both the outer\n  transaction (the Rails or Sinatra action) and the inner transaction (the\n  method given to add_transaction_tracer). This has been fixed, so only the\n  outermost transaction will now record queue time.\n\n    See https://github.com/newrelic/rpm/blob/master/CHANGELOG for a full list of\n    changes.\n"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "New Relic Ruby Agent"]
  s.rubygems_version = "2.4.6"
  s.summary = "New Relic Ruby Agent"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, ["= 10.1.0"])
      s.add_development_dependency(%q<minitest>, ["~> 4.7.5"])
      s.add_development_dependency(%q<mocha>, ["~> 0.13.0"])
      s.add_development_dependency(%q<sdoc-helpers>, [">= 0"])
      s.add_development_dependency(%q<rdoc>, [">= 2.4.2"])
      s.add_development_dependency(%q<rails>, ["~> 3.2.13"])
      s.add_development_dependency(%q<sqlite3>, ["= 1.3.8"])
      s.add_development_dependency(%q<sequel>, ["~> 3.46.0"])
      s.add_development_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<guard>, ["~> 1.8.3"])
      s.add_development_dependency(%q<guard-minitest>, [">= 0"])
      s.add_development_dependency(%q<rb-fsevent>, ["~> 0.9.1"])
    else
      s.add_dependency(%q<rake>, ["= 10.1.0"])
      s.add_dependency(%q<minitest>, ["~> 4.7.5"])
      s.add_dependency(%q<mocha>, ["~> 0.13.0"])
      s.add_dependency(%q<sdoc-helpers>, [">= 0"])
      s.add_dependency(%q<rdoc>, [">= 2.4.2"])
      s.add_dependency(%q<rails>, ["~> 3.2.13"])
      s.add_dependency(%q<sqlite3>, ["= 1.3.8"])
      s.add_dependency(%q<sequel>, ["~> 3.46.0"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<guard>, ["~> 1.8.3"])
      s.add_dependency(%q<guard-minitest>, [">= 0"])
      s.add_dependency(%q<rb-fsevent>, ["~> 0.9.1"])
    end
  else
    s.add_dependency(%q<rake>, ["= 10.1.0"])
    s.add_dependency(%q<minitest>, ["~> 4.7.5"])
    s.add_dependency(%q<mocha>, ["~> 0.13.0"])
    s.add_dependency(%q<sdoc-helpers>, [">= 0"])
    s.add_dependency(%q<rdoc>, [">= 2.4.2"])
    s.add_dependency(%q<rails>, ["~> 3.2.13"])
    s.add_dependency(%q<sqlite3>, ["= 1.3.8"])
    s.add_dependency(%q<sequel>, ["~> 3.46.0"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<guard>, ["~> 1.8.3"])
    s.add_dependency(%q<guard-minitest>, [">= 0"])
    s.add_dependency(%q<rb-fsevent>, ["~> 0.9.1"])
  end
end
