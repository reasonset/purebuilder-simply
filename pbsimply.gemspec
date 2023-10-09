Gem::Specification.new do |s|
  s.name        = 'pbsimply'
  s.version     = '3.0.0'
  s.summary     = 'PureBuiler Simply'
  s.description = 'Pre compile, static serving website builder.'
  s.authors     = ["Masaki Haruka"]
  s.email       = ["yek@reasonset.net"]
  s.files       = [
    "lib/pbsimply.rb",
    "lib/pbsimply/docdb.rb",
    "lib/pbsimply/docengine/base.rb",
    "lib/pbsimply/docengine/docutils.rb",
    "lib/pbsimply/docengine/misc.rb",
    "lib/pbsimply/docengine/pandoc.rb",
    "lib/pbsimply/docengine/rdoc.rb",
    "lib/pbsimply/prayer.rb",
    "lib/pbsimply/plugger.rb",
    "lib/pbsimply/hooks.rb",
    "lib/pbsimply/frontmatter.rb",
    "lib/pbsimply/accs.rb"
  ]
  s.homepage    = "https://github.com/reasonset/purebuilder-simply"
  s.license     = 'Apache-2.0'
  s.executables << "pbsimply"
  s.executables << "pbsimply-testserver"
end
