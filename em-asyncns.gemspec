# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{em-asyncns}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Stephan Maka"]
  s.date = %q{2009-05-11}
  s.description = %q{libasyncns binding for EventMachine}
  s.email = %q{stephan@spaceboyz.net}
  s.extensions = ["ext/em_asyncns/extconf.rb"]
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    "README.md",
    "Rakefile",
    "VERSION.yml",
    "ext/em_asyncns.cc",
    "ext/em_asyncns/asyncns.h",
    "ext/em_asyncns/em_asyncns.cc",
    "ext/em_asyncns/extconf.rb",
    "lib/Dnsruby.rb",
    "lib/em/resolver.rb",
    "lib/em_asyncns.so"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/astro/em-asyncns}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{Resolve domain names from EventMachine with libasyncns}
  s.test_files = [
    "spec/asyncns_spec.rb",
    "spec/resolver_spec.rb",
    "spec/dnsruby_spec.rb",
    "examples/loop-localhost.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0"])
  end
end
