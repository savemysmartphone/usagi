Gem::Specification.new do |s|
  s.name        = 'usagi'
  s.version      = '1.0.0'
  s.platform     = Gem::Platform::RUBY
  s.licenses     = ['MIT']
  s.summary      = '兎 - Usagi is a functional test suite for rails APIs'
  s.homepage     = 'https://github.com/savemysmartphone/usagi'
  s.description  = 'Functional test suite for rails APIs'
  s.authors      = ["Arnaud 'red' Rouyer", "Alice Clavel"]

  s.files        = `git ls-files`.split("\n")
  s.executables  << 'usagi'
  s.require_path = 'lib'
  s.required_ruby_version = '>= 2.0.0'
end
