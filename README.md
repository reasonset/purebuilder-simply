# Purebuilder Simply

Programmable static site generator supporting Markdown, reStructuredText, and RDoc via pluggable engines and CLI-based workflows.

## What is PureBuilder

PureBuilder Simply is a pre-built website building tool. It is also called a headless CMS or SSG.

It is easy to build and update, excels in writing functions, and is suitable for building text-centric websites.

## What is ACCS

ACCS is site building script for serialized articles.

PB Simply ACCS make `index.md` with indexes build by PureBuilder.

## Install

### Install from rubygems.org

`gem install pbsimply`

### Manually make Gem

* `gem build pbsimply.gemspec`
* `gem install pbsimply-$version.gem`

### Manually from GitHub

* `git clone https://github.com/reasonset/purebuilder-simply`
* Copy under `bin/` files on your PATH directory.
* Copy under `lib/` files on your Ruby library directory.

## Dependency

* Ruby >= 3.0
* Pandoc >= 2.8 (Optional)
* Docutils (Optional)
* redcarpet Gem (Optional)
* kramdown Gem (Optional)
* commonmarker Gem (Optional)

## Usage

### Create a Project

Use `pbsimply-init` to generate a project directory with both the document source root (`Source`) and the document build root (`Build`):

```bash
pbsimply-init
```

- You can pass a directory name as an argument.  
- If omitted, the current directory will be used.  
- The directory must be empty.  

You can also specify a theme for initialization with the `-t` option.

### Build Documents

Move into the document source root and run:

```bash
pbsimply directory
```

PureBuilder Simply will process the documents in the given directory and output HTML files.

## Documentation

For more details, see the [project homepage](https://purebuilder.app/).  
