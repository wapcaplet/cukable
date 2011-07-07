Gem::Specification.new do |s|
  s.name = "cukable"
  s.version = "0.1.2.beta"
  s.summary = "Runs Cucumber tests from FitNesse"
  s.description = <<-EOS
    Cukable allows running Cucumber test scenarios from FitNesse
  EOS
  s.authors = ["Eric Pierce", "Ken Brazier"]
  s.email = "wapcaplet88@gmail.com"
  s.homepage = "http://github.com/wapcaplet/cukable"
  s.platform = Gem::Platform::RUBY

  s.add_dependency 'json'
  s.add_dependency 'cucumber'
  s.add_dependency 'diff-lcs'

  s.add_development_dependency 'rake', '~> 0.8.7'
  s.add_development_dependency 'rspec', '>= 2.2.0'
  s.add_development_dependency 'rcov'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'bluecloth'

  s.files = `git ls-files`.split("\n")
  s.require_path = 'lib'

  s.executables = ['cuke2fit']
end
