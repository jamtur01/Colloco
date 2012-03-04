$:.push File.expand_path("../lib", __FILE__)

require 'version'

Gem::Specification.new do |s|
  s.name = "colloco"
  s.version = Colloco::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["James Turnbull"]
  s.description = "A web-based front-end and tool for tracking my map collection."
  s.email = "james@lovedthanlost.net"
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = `git ls-files`.split("\n")
  s.homepage = "http://github.com/jamtur01/colloco/"
  s.licenses = ["APL2"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "A web-based front-end and tool for tracking my map collection."
  s.add_dependency(%q<sinatra>, [">= 0"])
  s.add_dependency(%q<sqlite3>, [">= 0"])
  s.add_dependency(%q<data_mapper>, [">= 0"])
  s.add_dependency(%q<dm-sqlite-adapter>, [">= 0"])
end

