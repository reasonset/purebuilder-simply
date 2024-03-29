# Purebuilder Simply

Simplified website building system with Pandoc.

## What is PureBuilder

PureBuilder is website building script.

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

## Get start

* Make your document root
* Create and edit `.pbsimply.yaml` in your document root.
* Make directory and documents (Markdown or ReSTructured Text)
* Make template with `pandoc -D html5 > template.html` and edit it.

## Dependency

* Ruby >= 3.0
* Pandoc >= 2.8

## Usage

### PureBuilder

Move your document root before running.

	pbsimply directory

PureBuilder builds documents in the directory.

PureBuilder skip if filename start with `draft-` or `.`, or `draft` value in frontmatter is true.

### Options

|Option|Description|
|------|------------------------------|
|`-f`|Refresh all documents (force update mode.) This options useful when update template.|
|`-I`|Don't register to index database.|
|`-A`|Don't treat ACCS.|
|`-o FILE`|Output to FILE.|
|`-m FILE`|Additional meta (YAML) File.|

### Make ACCS index

`pbsimply` find ACCS documents directory automatically.
You mark as "ACCS documents directory" with putting `.accs.yaml` file to the directory.

ACCS processor makes and puts `index.html` file.

## Objects for eRuby in document

You can use these objects in eRuby on template or generated document.

### @config

Loaded config YAML file (`.pbsimply.yaml`).

### @indexes

Compiled index.

This object may be uncompleted when generating `pbsimply`.

### @index

Document meta data that "default | indexed | frontmatter | current".

### Index database

Documents metadata will be stored to index database on each document directory.

Ruby Marshal is used by default, the filename is `.indexes.rbm`.

If `json` or `oj` is set to `dbstyle` in configuration,
JSON is used instead of Ruby Marshal and hhe filename is `.indexes.json`

## Values in config.

|Key|Type|Description|
|-------|-----|---------------------|
|outdir|String|Base directory for output. Required|
|template|String|Path to Pandoc HTML template file. If not set, template is `temaplte.html`|
|css|String / Array|Path to CSS file(s)|
|toc|Boolean|Turn on TOC if true|
|pandoc\_additional\_options|Array|Extra pandoc options|
|post\_eruby|Boolean|Process Pandoc output with eRuby if true|
|alt\_frontmatter|Hash|Default frontmatter in ACCS index|
|default\_meta|Hash|Default frontmatter|
|testserver\_port|Fixnum|Port number of pbsimply-testserver (default 8000)|
|self\_url\_prefix|String|Absolute path prefix for URL of generated document itself instead of `/`.|
|self\_url\_external\_prefix|String|Like `self_url_prefix`, but it only works on `page_url_encoded_external`.|
|dbstyle|String|If `json` given, Indexes database is used `.indexes.json` instead of `.indexes.rbm`. Also `oj` is same as it, but use `Oj` library instead of `JSON` standard library.|
|bless\_style|String|If `cmd` given, blessing with command instead of Ruby procs.|
|bless\_cmd|String / Array|Command for blessing.|
|bless\_accscmd|String / Array|Command for ACCS blessing.|
|blessmethod\_accs\_rel|String|Automatic blessing method for find next/prev article.|
|accs\_order|String|If `desc` is set, ACCS article list is sorted by descending order (on default template.)|
|accs\_across\_category|Boolean|Don't separate ACCS article lists by category (on default template.)|
|accs\_sort\_by|String|Sorting method for ACCS article list. `default` (date, title, last update), `title` (title, date), `name` (filename, title, date) and `serial` (`serial`, date, filename) are avilable. It works on default template.|
|auto\_delete|Boolean|Delete output file when source file is deleted or turned to draft.|
|detect\_modification|String|Detecting modification method. `changes` looks change `changes` header. `mtimesize` looks mtime and file size. Otherwise, it looks mtime.|
|pandoc\_command|String|Pandoc command. `pandoc` is default.|


## Special values in @index

|Key|Set by|Used by|Description|
|-------|------------|------------|-----------------------------------|
|title|frontmatter|Pandoc/System|Document title. required.|
|author|frontmatter|Default template|Author.|
|date|frontmatter/system|System|Date of written|
|lang|frontmatter|Pandoc template|`lang`/`xml:lang`|
|keywords|frontmatter|Pandoc template|An array, used as keywords in meta tag.|
|description|frontmatter|Sample template|Used as description in meta tag.|
|draft|frontmatter|System|Draft status. Skip process document if true.|
|\_last\_proced|system|system|*Integer*. DateTime of last processed by PureBuilder. `0` if this document is processed first.|
|last\_updated|system||*String*. DateTime of last processed by Pandoc.|
|\_size|system||File size (byte)|
|\_mtime|system||*Integer*. mtime of this file.|
|\_filename|system||File name|
|\_docformat|system||Document Format. `Markdown` or `ReST`.|
|categories|frontmatter|ACCS|Document category. Sort documents by this value.
|pagetype|frontmatter/config|ACCS|Document type of this page. `accsindex` is set if processed by ACCS, set `post` by default.|
|source\_directory|system||Source directory string.|
|source\_file|system||Source Filename.|
|source\_path|system||Source path string.|
|dest\_path|system|system|Output file path.|
|normalized\_docdir|system||Normalized source document directory path, begin with `/`.|
|normalized\_docpath|system||Normalized source document path, begin with `/`.|
|page\_url|system||This (generated) page's URL.|
|page\_url\_encoded|system||This (generated) page's URI encoded URL.|
|page\_url\_encoded\_external|system||This (generated) page's URI encoded URL with `self_url_external_prefix`.|
|title\_encoded|system||URI encoded document title.|
|timestamp|frontmatter|system|The date and time of the document which is more detailed than `date`.|
|timestamp\_xmlschema|system||XML Schema formatted Timestamp. Use `date` instead of `timestamp` if `timestamp` isn't defined.|
|timestamp\_jplocal|system||Japanese local formatted Timestamp. Use `date` instead of `timestamp` if `timestamp` isn't defined.|
|timestamp\_rubytimestr|system||Ruby's `Time#to_s` like formatted Timestamp. Use `date` instead of `timestamp` if `timestamp` isn't defined.|
|timestamp\_str|system||`%Y-%m-%d[ %H:%M:%S %Z]`. Use `date` instead of `timestamp` if `timestamp` isn't defined.|

## Environment variables

Environment variables that able to use in Pre Plugins, Post plugins, Hooks or Blessing command.

|Name|Pre|Process|Delete|Post|Bless|Description|
|---------|---|---|---|--------------------|
|`pbsimply_outdir`|Yes|Yes|Yes|Yes|Yes|Path for output directory root.|
|`pbsimply_subdir`|Yes|Yes|Yes|Yes|Yes|Path for document directory from document root.|
|`pbsimply_indexes`|Yes|Yes|Yes|Yes|Yes|Path for index database.|
|`pbsimply_frontmatter`|Yes|Yes|Yes|Yes|Yes|Path for current document's frontmatter (JSON).|
|`pbsimply_working_dir`|Yes|Yes|Yes|Yes|Yes|Temporary directory path for putting processing data.|
|`pbsimply_currentdoc`|Yes|Yes|No|No|No|Temporary filepath for processing document.|
|`pbsimply_filename`|Yes|Yes|No|No|No|Original source filename.|

## Testing

CSS, image or link locations should **not** be local place, *path to web URL*, so you cannot test generated documents normally case of suppose to put to WWW.

You can test in case like it with `pbsimply-testserver`.

How to use is very simple.

1. Move your document root
2. run it.
3. access `http://localhost:port`

You can config port with `testserver_port` in config file. default is 8000.

If you think to put subdirectory like `http://example.com/site/index.html`,
I recommend that you put document in `site` subdirectory, and sync under there.

## Blessing

### With Ruby

You can modify Frontmatter with Ruby script with `.pbsimply-bless.rb` file.

If you want to use it, you should `PureBuilder::BLESS` Proc object in the file.
It will be called with `PureBuilder::BLESS.call(frontmatter, self)`.

This proc will be called after system paramaters were set.

It don't need to return something.
You can modify frontmatter Hash object directly.

When processing directory is an ACCS document directory,
`PureBuilder::ACCS::BLESS` is also called after `PureBuilder::BLESS` if defined.

You can add keys and `Proc` values to `PureBuilder::ACCS::DEFINTIONS` Hash.
They are used for setting special value.

|Key|Function|
|-----|-------------------------|
|`:next`|Set returned value to `frontmatter["next_article"]`|
|`:prev`|Set returned value to `frontmatter["prev_article"]`|

For example, this is [Chienomi](https://chienomi.org/)'s blessing script.

```ruby
#!/usr/bin/ruby

load "./.lib/categories.rb"

TOPICPATH = {
  "" => ["TOP", "/"],
  "/articles" => ["Articles", "/#Category"],
  "/override" => ["Override", "/"],
  "/archives" => ["Old Archives", "/articlelist-wp.html"]
}

ARTICLE_CATS.each do |k,v|
  TOPICPATH[["/articles", k].join("/")] = [v, ["", "articles", k, ""].join("/")]
end

PureBuilder::BLESS = ->(frontmatter, pb) {
  content = nil
  filetype = nil
  content = File.read(frontmatter["source_path"])
  filetype = File.extname(frontmatter["_filename"])

  url = frontmatter["page_url"].sub(/^\.?\/?/, "/")
  frontmatter["topicpath"] = []
  url = url.split("/")
  (1 .. url.length).each do |i|
    path = url[0, i].join("/")
    if v = TOPICPATH[path]
      frontmatter["topicpath"].push({"title" => v[0], "url" => v[1]})
    else
      frontmatter["topicpath"].push({"title" => frontmatter["title"]})
      break
    end
  end

  if frontmatter["category"] && url.include?("articles")
    frontmatter["category_spec"] = [ARTICLE_CATS[url[-2]], frontmatter["category"]].join("::")
  end

  if content
    if((filetype == ".md" && content =~ %r:\!\[.*\]\(/img/thumb/:) || (filetype == ".rst" || filetype == ".rest") && content =~ %r!\.\. image:: .*?/img/thumb!)
      frontmatter["lightbox"] = true
    end
  end
}

article_order = nil
rev_article_order_index = {}

PureBuilder::ACCS::BLESS = -> (frontmatter, pb) {
  frontmatter["ACCS"] = true
  unless article_order
    article_order = pb.indexes.to_a.sort_by {|i| i[1]["date"]}
    article_order.each_with_index {|x,i| rev_article_order_index[x[0]] = i }
  end
}

PureBuilder::ACCS::DEFINITIONS[:next] = ->(frontmatter, pb) {
  index = rev_article_order_index[frontmatter["_filename"]] or next nil
  if article_order[index + 1]
    {"url" => article_order[index + 1][1]["page_url"],
     "title" => article_order[index + 1][1]["title"]}
  end
}

PureBuilder::ACCS::DEFINITIONS[:prev] = ->(frontmatter, pb) {
  index = rev_article_order_index[frontmatter["_filename"]] or next nil
  if index > 0
    {"url" => article_order[index - 1][1]["page_url"],
     "title" => article_order[index - 1][1]["title"]}
  end
}
```

### With other language or programs

If `cmd` is set to `bless_style` in configuration, use external command instead of Ruby procs.

`bless_cmd` is command for blessing.
`bless_accscmd` is command for ACCS blessing.

You can read document metadata from `pbsimply-frontmatter.json` file on directory `$pbsimply_working_dir` environment variable,
and you can apply changes with write to the file.

### Automatic blessing

Some configuration applies prepared blessing method.

#### ACCS Relation

`blessmethod_accs_rel` makes `next_article` and `prev_article` property.
They are an associative array that have keys `url` and `title`.

`numbering` (heading number of filename), `lexical` (filename), `date` and `timestamp` are avilable.

## Files

### In this repository

|Filename|Description|
|--------|-------------|
|pbsimply-testserver|Satrt web server for testing.|
|accsindex.erb|Sample for `.accsindex.erb`. Normaly you don't need to edit template.|
|docroot-sample|For (part) copy to your document root.|
|template.html|Sample for PureBuilder template.|
|postgenerate|Sample files for post generate script.|

### You put or generated

|Filename|Place|Description|
|--------|-----------|-------------|
|.pbsimply.yaml|root|Configuration file. Put in document root.|
|.indexes.rbm|each|metadata Ruby marshal file generated by PureBuilder Simply.|
|.indexes.json|each|metadata JSON file generated by PureBuilder Simply.|
|.index.md|each|Index source generated by ACCS.|
|.accsindex.erb|root or each ACCS|Markdown eRuby template for ACCS index.|
|.accs.yaml|each|`@index` for the ACCS index.|
|.pbsimply-bless.rb|root|Ruby script for blessing.|

# Document Sample

## Template

This template is associeted to basic blog theme.

I customized:

* Two Headers. `#TopHeader` for banner (default `display: none`), `#TitleHeader` for title.
* Main section is wrapped by `#MainContainer` section.
* Article body is wrapped by `#MainArticle` article.
* Side bar is available as `#SideBar` section. You can write content with include before function.
* Author section is deleted.
* Embedded CSS is deleted.
* Syntax highlightning theme is deleted. If you need it, get themes from [pandoc-goodies](https://github.com/tajmone/pandoc-goodies) or other.

## CSS

Basic sample CSS.

|file|description|
|---------|----------------------|
|layout.css|Layouting.|
|base.css|Basic design.|
|skylightning.css|Pandoc default Source code CSS|
|lightbox.css|Lightbox theme for lightbox plugin.|

## Post

ACCS template directory.

## Post Generate

Sample Post Plugins.

## Configuration file

`.accsindex.rb` and `.pbsimply.yaml` are avialable.

## JavaScript

JavaScript Plugins.

See README on each file.

## Themes

You can use sample Themes with merge content to copied sample document directory.

### Base

![Default theme](img/theme-base.png)

### Warm

![Warm colored theme](img/theme-warm.png)

### Practical

![Basic theme like reports](img/theme-practical.png)

### Bloggy

![Typical blog theme](img/theme-bloggy.png)

## Use a processor instead of Pandoc

### Basics

PureBuilder Simply is a very powerful tool when used with Pandoc, but if you do not prefer Pandoc, you can use other document processors.

However, it is limited in its functionality.

The processor to use is specified with the value of `pbsimply_processor` in `.pbsimply.yaml`.

|Processor|pbsimply_processor|
|--------|-------------------|
|RDoc|`rdoc`|
|RDoc/Markdown|`rdoc_markdown`|
|Kramdown|`kramdown`|
|Redcarpet|`redcarpet`|
|CommonMarker (cmark-gfm)|`cmark`|

Also, for those templates that evaluate as eRuby templates, you can use the following values on the template (in most cases, use `frontmatter` and `article_body`.)

|Variable name|Description|
|--------|--------------------------|
|`dir`|Relative directory path from document root.|
|`filename`|Source file name.|
|`frontmatter`|Blessed metadata.|
|`orig_filepath`|Original source filepath.|
|`procdoc`|Actual (treated) source filepath.|
|`article_body`|Generated document body.|

### RDoc

#### Summery

It uses RDoc, the standard documentation system of Ruby.
Source files are treated as RDoc, and the target is limited to `*.rdoc` files.

Templates are handled as eRuby templates.

#### Dependency

* rdoc library

#### Disabled configurations

* `css`
* `toc`
* `pandoc_additional_options`
* `post_eruby`

### RDoc/Markdown

#### Summery

Use the Markdown processor of RDoc, Ruby's standard document system.
Treat source files as if they were Markdown, limited to `*.md` files.

Templates are handled as eRuby templates.

#### Dependency

* rdoc library

#### Disabled configurations

* `css`
* `toc`
* `pandoc_additional_options`
* `post_eruby`

### Kramdown

#### Summery

It is generated using Kramdown, Ruby's Markdown library.
Treat source files as if they were Markdown, limited to `*.md` files.

Templates are handled as eRuby templates.

#### Dependency

* kramdown library

#### Disabled configurations

* `css`
* `toc`
* `pandoc_additional_options`
* `post_eruby`

#### Additional configurations

|Key|Type|Description|
|-------|-----|-----------------------|
|`kramdown_features`|Hash|An associative array passed as the second argument to `Kramdown::Document.new`. See the [API documentation for details]. (https://kramdown.gettalong.org/rdoc/Kramdown/Options.html)|

### Redcarpet

#### Summery

It is generated using Redcarpet, Ruby's Markdown library.
Treat source files as if they were Markdown, limited to `*.md` files.

Templates are handled as eRuby templates.

#### Dependency

* redcarpet library

#### Disabled configurations

* `css`
* `toc`
* `pandoc_additional_options`
* `post_eruby`

#### Additional configurations

|Key|Type|Description|
|-------|-----|-----------------------|
|`redcarpet_extensions`|Hash|An associative array showing the extensions to Redcarpet. See the [Redcarpet page](https://github.com/vmg/redcarpet) for details.|

### Redcarpet

#### Summery

Generated using CommonMarker, a Ruby wrapper for `libcmark-gfm`.
Source files are treated as Markdown, and the target is limited to `*.md` files.

The `table` and `strikethrough` extensions are enabled.

Templates are handled as eRuby templates.

#### Dependency

* libcmark-gfm
* commonmarker library
*
#### Disabled configurations

* `css`
* `toc`
* `pandoc_additional_options`
* `post_eruby`

### Docutils

#### 説明

Generated using Docutils ReSTructured Text processor written by Python.
Source files are treated as ReSTructured Text, and the target is limited to `*.rst` files.

#### Dependency

* Docutils (`rst2html5`)

#### Disabled configurations

* `toc`
* `pandoc_additional_options`

#### Additional configurations

|Key|Type|Description|
|-------|-----|-----------------------|
|`docutils_options`|Array|Command-line option arguments for `rst2html5` command.|

# Hooks

## Overview

You can tweak PureBuilder Simply behavior with hooks feature.

write `.pbsimply-hooks.rb` on document root to use Hooks.
It should define `PBSimply::Hooks.load_hooks`.

It called with `PBSimply::Hooks` object.
`PBSimply::Hooks` object has "timing" methods. You can add `Proc` to timing object with `<<` method.

```ruby
#!/bin/ruby

def (PBSimply::Hooks).load_hooks h
  h.process << ->(v) {
    db[v["normalized_docpath"]] = v
  }

  h.post << ->(v) {
    db.delete_if do |dbk, dbv|
      not File.exist? dbv["dest_path"]
    end
  }
end
```

Hook called with one argument. Ordinary it is a `Hash`, but keys and values are different between timing object.

## Timing methods

Methods of argument of `PBSimply::Hooks#load_hooks`.

### `#add {|arg| ... }`

Add block to timing object.

### `#<< proc`

Add proc to timing object.

### `#cmd(*cmdarg)`

Call command with `system(*cmdarg)`.

You can modify content of `$pbsimply_currentdoc` on `pre`.

### `#filter(*cmdarg)`

Call command with `IO.popen(cmdarg, "w+")`.

Command is given document content from STDIN, and overwrite document content with command's output.

you can use this method *only* on `pre`.

## Timing object

### pre

`PBSimply::Hooks#pre` is called before processing document.

Argument are `frontmatter` and `procdoc`.

`pre` is called after BLESSing.

`procdoc` is processing document's temporary path.
Its content same as source document but without frontmatter.

### process

`PBSimply::Hooks#process` is called just after generating.

Arguments are `frontmatter`, `procdoc`, `outpath`.

`frontmatter` and `procdoc` are same as `#pre`, but after other process.
`outpath` is output file path.

### delete

`PBSimply::Hooks#delete` is called when document is lost include it turn to draft.

Arguments are `target_file_path` and `source_file_path`.

`target_file_path` is output file path (existing or non-existing.)

`source_file_path` is source file path (existing or non-existing.)

## post

`PBsimply::Hooks#post` is called after all document processed.

Argument is `this_time_processed`.

`this_time_processed` is an `Array` of `Hash` actual processed documents in this time.

It has `source` (original source file path,) `dest` (output file path,) `frontmatter`.

### accs 

`PBSimply::Hooks#accs` is called before generating ACCS index.

Arguments are `index` and `indexes`.
They are same as `@index` and `@indexes` in `.accsindex.erb`.