# Purebuilder Simply

Simplified website building system with Pandoc.

## What is PureBuilder

PureBuilder is website building script.

## What is ACCS

ACCS is site building script for serialized articles.

PB Simply ACCS make `index.md` with indexes build by PureBuilder.

## Install

* Copy every Ruby script your PATH directory.
* Make your document root
* Create and edit `.pbsimply.yaml` in your document root.
* Make directory and documents (Markdown or ReSTructured Text)
* Make template with `pandoc -D html5 > template.html` and edit it.

## Dependency

* Ruby >= 2.3
* Pandoc >= 2.8

## Usage

### PureBuilder

Move your document root before running.

	pbsimply-pandoc.rb directory

PureBuilder builds documents in the directory.

PureBuilder skip if filename start with `draft-` or `.`, or `draft` value in frontmatter is true.

### Options

|Option|Description|
|------|------------------------------|
|`-f`|Refresh all documents (force update mode.) This options useful when update template.|
|`-I`|Don't register to index database.|
|`-o FILE`|Output to FILE.|
|`-m FILE`|Additional meta (YAML) File.|

### Make ACCS index

`pbsimply-pandoc.rb` find ACCS documents directory automatically.
You mark as "ACCS documents directory" with putting `.accs.yaml` file to the directory.

ACCS processor makes and puts `index.html` file.

## Objects for eRuby in document

You can use these objects in eRuby on template or generated document.

### @config

Loaded config YAML file (`.pbsimply.yaml`).

### @indexes

Compiled index.

This object may be uncompleted when generating `pbsimply-pandoc.rb`.

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
|toc|Boolian|Turn on TOC if true|
|pandoc\_additional\_options|Array|Extra pandoc options|
|post\_eruby|Boolian|Process Pandoc output with eRuby if true|
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
|accs\_across\_category|Boolian|Don't separate ACCS article lists by category (on default template.)|
|accs\_sort\_by|String|Sorting method for ACCS article list. `default` (date, title, last update), `title` (title, date), `name` (filename, title, date) and `serial` (`serial`, date, filename) are avilable. It works on default template.|

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
|\_last\_proced|system||*Integer*. DateTime of last processed by PureBuilder. `0` if this document is processed first.|
|last\_updated|system||*String*. DateTime of last processed by Pandoc.|
|\_size|system||File size (byte)|
|\_mtime|system||*Integer*. mtime of this file.|
|\_filename|system||File name|
|\_docformat|system||Document Format. `Markdown` or `ReST`.|
|categories|frontmatter|ACCS|Document category. Sort documents by this value.
|pagetype|frontmatter/config|ACCS|Document type of this page. `accsindex` is set if processed by ACCS, set `post` by default.|
|source\_directory|system||Source directory string. Set by PureBuilder.|
|source\_file|system||Source Filename. Set by PureBuilder.|
|source\_path|system||Source path string. Set by PureBuilder.|
|page\_url|system||This (generated) page's URL. Set by PureBuilder.|
|page\_url\_encoded|system||This (generated) page's URI encoded URL. Set by PureBuilder.|
|page\_url\_encoded\_external|system||This (generated) page's URI encoded URL with `self_url_external_prefix`. Set by PureBuilder.|
|title\_encoded|system||URI encoded document title. Set by PureBuilder.|
|timestamp|frontmatter|system|The date and time of the document which is more detailed than `date`.|
|timestamp\_xmlschema|system||XML Schema formatted Timestamp. Use `date` instead of `timestamp` if `timestamp` isn't defined.|
|timestamp\_jplocal|system||Japanese local formatted Timestamp. Use `date` instead of `timestamp` if `timestamp` isn't defined.|
|timestamp\_rubytimestr|system||Ruby's `Time#to_s` like formatted Timestamp. Use `date` instead of `timestamp` if `timestamp` isn't defined.|
|timestamp\_str|system||`%Y-%m-%d[ %H:%M:%S %Z]`. Use `date` instead of `timestamp` if `timestamp` isn't defined.|

## Environment variables

Environment variables that able to use in Pre Plugins, Post plugins, Blessing command.

|Name|Pre|Post|Bless|Description|
|---------|---|---|---|--------------------|
|`pbsimply_outdir`|Yes|Yes|Yes|Path for output directory root.|
|`pbsimply_subdir`|Yes|Yes|Yes|Path for document directory from document root.|
|`pbsimply_indexes`|Yes|Yes|Yes|Path for index database.|
|`pbsimply_frontmatter`|Yes|Yes|Yes|Path for current document's frontmatter (JSON).|

## Testing

CSS, image or link locations should **not** be local place, *path to web URL*, so you cannot test generated documents normally case of suppose to put to WWW.

You can test in case like it with `pbsimply-testserver.rb`.

How to use is very simple.

1. Move your document root
2. run it.
3. access `http://localhost:port`

You can config port with `testserver_port` in config file. default is 8000.

If you think to put subdirectory like `http://example.com/site/index.html`,
I recommend that you put document in `site` subdirectory, and sync under there.

## Pre processing

if you put scripts in `.pre_generate`, PureBuilder Simply Pandoc executes these files each of before generating.

Scripts are invoked by `perl` for udnerstanding shebang line.

Each scriped is called with

```
perl <script> <temporary_source_file>
```

PureBuilder Simply replaces temporary source file with script output.

Script **cannot** use index database because this script is called each generating.

Pre script called just before generating. Not called with skipped document.

## Post processing

if you put scripts in `.post_generate`, PureBuilder Simply Pandoc executes these files after generating.

Scripts are invoked by `perl` for udnerstanding shebang line.

Each scriped is called with

```
perl <script> <generated_file>
```

PureBuilder Simply replaces generated file with script output.

Scripts can use index database.
You can get database path from `$pbsimply_indexes` environment variable.

Processing document's meta infomation is in `$pbsimply_doc_frontmatter` environment variable with YAML.

You can access the document's sub-directory part with `$pbsimply_subdir` environment variable.

Post script called from generated file list.
They aren't called by already generated files without generating this time.

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

You can read document metadata from `.pbsimply-frontmatter.json` file,
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
|pbsimply-testserver.rb|Satrt web server for testing.|
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
|.post_generate|root|Script files for process each documents after generating.|
|.pre\_generate|root|Script files for process each documents before generating.|
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