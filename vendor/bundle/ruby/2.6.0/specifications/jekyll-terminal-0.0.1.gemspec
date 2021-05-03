# -*- encoding: utf-8 -*-
# stub: jekyll-terminal 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "jekyll-terminal".freeze
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Xavier Decoret".freeze]
  s.date = "2014-12-13"
  s.description = "Displays nice ".freeze
  s.email = "xavier.decoret+jekyll@gmail.com".freeze
  s.homepage = "http://rubygems.org/gems/jekyll-terminal".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Gem to show terminals in Jekyll sites".freeze

  s.installed_by_version = "3.0.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<jekyll>.freeze, ["~> 2.0"])
    else
      s.add_dependency(%q<jekyll>.freeze, ["~> 2.0"])
    end
  else
    s.add_dependency(%q<jekyll>.freeze, ["~> 2.0"])
  end
end
