Gem::Specification.new do |s|
  s.required_ruby_version = ">= 2.6"
  s.name        = 'pbsimply'
  s.version     = '3.3.0'
  s.summary     = 'PureBuiler Simply'
  s.description = 'Pre compile, static serving website builder.'
  s.authors     = ["Masaki Haruka"]
  s.email       = ["yek@reasonset.net"]
  
  s.files       = Dir["lib/**/*.rb"]
  s.files      += Dir["themes/**/*"]
  s.files      += Dir["themes/**/.*"]
  s.homepage    = "https://github.com/reasonset/purebuilder-simply"
  s.license     = 'Apache-2.0'
  s.executables << "pbsimply"
  s.executables << "pbsimply-testserver"
  s.executables << "pbsimply-init"
end
