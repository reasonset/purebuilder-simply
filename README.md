# Purebuilder Simply
Simplified website building system with Pandoc.

## What is PureBuilder

PureBuilder is website building script.

## What is ACCS

ACCS is site building script for serialized articles.

PB Simply ACCS make `index.html` with indexes build by PureBuilder.

## Install

* Copy every Ruby script your PATH directory.
* Make your document root
* Create and edit `.pbsimply.yaml` in your document root.
* Make directory and documents (Markdown or ReSTructured Text)
* Copy `accsindex.erb` to `.accsindex.erb` in your document root and edit.
* Make template with `pandoc -D html5 > template.html` and edit it.

## Dependency

* Ruby >2.3
* Pandoc

## Usage

### PureBuilder

Move your document root before running.

	pbsimply-pandoc.rb directory

PureBuilder builds documents in the directory.

PureBuilder skip if filename start with `draft-` or `.`, or `draft` value in frontmatter is true.

### Make ACCS index

Before running, build your documents in the directory, and move your document root.

	pbsimply-accsindex.rb directory

PB Simply ACCS make `index.html`.

## Objects for eRuby in document

You can use these objects in eRuby on template or generated document.

### @config

Loaded config YAML file (`.pbsimply.yaml`).

### @indexes

Compiled index.

This object may be uncompleted when generating `pbsimply-pandoc.rb`.

### @index

Document meta data that "default | indexed | frontmatter | current".

## Values in config.

|Key|Type|Description|
|-------|-----|---------------------|
|outdir|String|Base directory for output. Required|
|template|String|Path to Pandoc HTML template file. If not set, template is `temaplte.html`|
|css|String / Array|Path to CSS file(s)|
|toc|Boolian|Turn on TOC if true|
|pandoc_additional_options|Array|Extra pandoc options|
|post_eruby|Boolian|Process Pandoc output with eRuby if true|
|alt_frontmatter|Hash|Default frontmatter in ACCS index|
|testserver_port|Fixnum|Port number of pbsimply-testserver (default 80)|

## Special values in @index

|Key|Set/Used by|Description|
|-------|------------|-----------------------------------|
|title|frontmatter|Document title. required.|
|author|frontmatter|Author.|
|date|frontmatter or system.|Date of written|
|lang|additional option / Pandoc template|`lang`/`xml:lang`|
|keywords|additional option / Pandoc template|An array, used as keywords in meta tag.|
|description|additional option / Sample template|Used as description in meta tag.|
|draft|additional option / system|Draft status. Skip process document if true.|
|_last_proced|system|*Integer*. DateTime of last processed by PureBuilder. `0` if this document is processed first.|
|last_updated|system|*String*. DateTime of last processed by PanDoc.|
|_size|system|File size (byte)|
|_mtime|system|*Integer*. mtime of this file.|
|_filename|system|File name|
|_docformat|system|Document Format. `Markdown` or `ReST`.|
|categories|ACCS|Document category. Sort documents by this value.
|pagetype|ACCS|Document type of this page. `accs_index` is set if processed by ACCS, set `post` by default.|
|accs_order|ACCS|Document order. If `desc` is set, document sort by descending order.|
|blogmode|ACCS|Document sort by descending order if this value is true.|

## Testing

CSS, image or link locations should **not** be local place, *path to web URL*, so you cannot test generated documents normally case of suppose to put to WWW.

You can test in case like it with `pbsimply-testserver.rb`.

How to use is very simple.

1. Move your document root
2. run it.
3. access `http://localhost:port`

You can config port with `testserver_port` in config file. default is 80.

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

Script **cannot** use `indexes.rbm` because this script is called each generating.

Processing document's meta infomation is in `$pbsimply_doc_frontmatter` environment variable.

Pre script called just before generating. Not called with skipped document.

## Post processing

if you put scripts in `.post_generate`, PureBuilder Simply Pandoc executes these files after generating.

Scripts are invoked by `perl` for udnerstanding shebang line.

Each scriped is called with

```
perl <script> <generated_file>
```

PureBuilder Simply replaces generated file with script output.

Scripts can use `indexes.rbm`.
You can get database path from `$pbsimply_indexes` environment variable.

Processing document's meta infomation is in `$pbsimply_doc_frontmatter` environment variable.

Post script called from generated file list.
They aren't called by already generated files without generating this time.

## Files

### In this repository

|Filename|Description|
|--------|-------------|
|pbsimply-testserver.rb|Satrt web server for testing.|
|accsindex.erb|Sample for `.accsindex.erb`. Normaly you don't need to edit template.|
|template.html|Sample for PureBuilder template.|
|tufie.css|Sample CSS file. This file forked from [otsaloma/markdown-css/tufie.css](https://github.com/otsaloma/markdown-css/blob/master/tufte.css). Thank you.|
|postgenerate|Sample files for post generate script.|

### You put or generated

|Filename|Place|Description|
|--------|-----------|-------------|
|.pbsimply.yaml|root|Configuration file. Put in document root.|
|.indexes.rbm|each|Ruby marshal file generated by PureBuilder Simply.|
|.index.md|each|Index source generated by ACCS.|
|.accsindex.erb|root or each ACCS|Markdown eRuby template for ACCS index.|
|.accs.yaml|each|`@index` for the ACCS index.|
|.post_generate|root|Script files for process each documents after generating.|
