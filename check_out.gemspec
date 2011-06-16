Gem::Specification.new do |s|
  s.name = "check_out"
  s.summary = "Let users `check out` Active Record instances and then release them when they're done editing."
  s.description = "Let users `check out` Active Record instances and then release them when they're done editing."
  s.files = Dir["lib/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.version = "0.0.1"
  s.authors = ["Nick Ragaz"]
  s.email = "nick.ragaz@gmail.com"
  s.homepage = "http://github.com/nragaz/check_out"
  
  s.add_dependency 'activerecord', '~> 3'
  s.add_dependency 'activesupport', '~> 3'
  
  s.add_development_dependency 'sqlite3'
end
