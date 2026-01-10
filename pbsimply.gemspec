Gem::Specification.new do |s|
  s.required_ruby_version = ">= 2.6"
  s.name        = 'pbsimply'
  s.version     = '3.6.2'
  s.summary     = 'Flexible and programmable static site generator with pluggable Markdown engines'
  s.description = 'A flexible, programmable static site generator for Markdown, reStructuredText, and RDoc formats. PureBuilder Simply supports both embedded and external content processors—including Kramdown, Redcarpet, Commonmarker, RDoc, Pandoc, Docutils—and enables customizable conversion workflows and CLI-based project generation.'

  s.authors     = ["Masaki Haruka"]
  s.email       = ["yek@reasonset.net"]

  s.files       = Dir["lib/**/*.rb"]
  s.files      += Dir["themes/**/*"].select {|i| File.file? i}.reject {|i| File.basename(i)[0,4] == ".git"}
  s.files      += Dir["themes/**/.*"].select {|i| File.file? i}.reject {|i| File.basename(i)[0,4] == ".git"}
  s.files      += ["README.md", "LICENSE"]
  s.homepage    = "https://purebuilder.app/"
  s.license     = 'Apache-2.0'
  s.executables << "pbsimply"
  s.executables << "pbsimply-testserver"
  s.executables << "pbsimply-init"

  s.metadata = {
    "homepage_uri"     => "https://purebuilder.app/",
    "source_code_uri"  => "https://github.com/reasonset/purebuilder-simply",
    "changelog_uri"    => "https://github.com/reasonset/purebuilder-simply/blob/master/CHANGELOG.md",
    "bug_tracker_uri"  => "https://github.com/reasonset/purebuilder-simply/issues"
  }
end
