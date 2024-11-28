require 'date'
require 'yaml'

PureBuilder::BLESS = ->(frontmatter, pb) {
  today = Date.today
  frontmatter["year"] = today.year

  menu = YAML.load File.read "menu.yaml"
  frontmatter["site-navigation"] = menu
}