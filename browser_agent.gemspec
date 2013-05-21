# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'browser_agent/version'

spec = Gem::Specification.new do |s|
  s.name = "browser_agent"
  s.version = BrowserAgent::VERSION
  s.author = "David Ricciardi"
  s.email = "nricciar@gmail.com"
  s.homepage = "http://github.com/nricciar/browser_agent"
  s.platform = Gem::Platform::RUBY
  s.summary = "A small library to aid in testing websites"
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = "lib"
  s.description = File.read("README")
  s.has_rdoc = false
  s.extra_rdoc_files = ["README","MIT-LICENSE"]
  s.description = %q{A small library to aid in testing websites}
  s.add_dependency 'cookiejar'
  s.add_dependency 'nokogiri'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency(RUBY_VERSION =~ /^1\.9/ ? "simplecov" : "rcov")
end
