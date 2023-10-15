# CHANGELOG

## v1.2 2018-02-07

* Support docinfo in ReST
* Skip if filename start with `draft-`
* Delete entry in indexes if not exist.

## v1.2.1 2018-02-21

* .accs_index.rbm is added index file list.
* Support Array metadata.

## v1.3 2018-05-20

* More suitable support for ReSTreuctured Text's docinfo.
* Commented out adding parsed metadata to commandline function.
  This feature is not necessary because Pandoc understand metadata right anyway.

## v1.4 2018-07-07

* Process temporary file instead of real document file.
* Support draft metadata. if draft is true, skip processing document.
* Add _docformat to doc metadata.
* Support $pbsimply_doc_frontmatter environment variable.
* Change $pbsimply-indexes to $pbsimply_indexes
* Add support Pre plugins.

## v1.4.1 2018-07-09

* Meta data give to pandoc with argument when ReST + docinfo for multiple element
* Add support docinfo term characters `-` and `_`.

## v1.4.2 2018-07-22

* Read .accsindex.erb on ACCS directory instead of the file on document root.

## v1.4.3 2018-08-02

* Keep plugin order.

## v1.4.4 2018-08-06

* Plugins can access subdirectory path with pbsimply_subdir environment variable.

## v1.4.5 2018-08-12

* Add Japanese README.

## v1.5 2018-08-14

* CHANGE LICENSE BSD 3-clause TO APACHE LICENSE 2.0
* Move document sample files to docroot-sample directory.
* New template and CSS files.
* Add JavaScript plugins.

## v1.6 2019-10-13

* Additional meta data support.
* Auto creating target directory.
* Force update mode.
* Support command line options.
* Bug fix: Post plugins didn't work in single mode.

## v1.6.1 2019-10-21

* More additional meta data support. (timestamp)
* Bug fix: wrong behavior on `-f` option.

## v1.7 2019-10-23

* Change test server's default port 80 to 8000.
* Converted timestamp uses dete if timestamp isn't defined.
* Add and rearrange sample docs.
* Directly execute plugins if it is executable, or call with script engine if known extension.

## v1.8 2020-02-25

**INCONPARTIBLE CHANGES!!!**

* Change to use `defaults` and `metadata-file`. Now PureBuilder Simply requires Pandoc >= 2.8.
* Add metadata `timestamp_str`.
* Add some metadata about timestamp and encoded value.

NOW `pandoc_additional_options` IS MERGED INTO `defaults`. IT IS NOT COMMANDLINE OPTION.

## v1.8.1 2020-02-26

* Add commandline options (`-o`, `-m`, `-I`, `-A`)
* Fix ACCS system (to use `pbsimply-pandoc.rb` command).

## v1.9 2020-03-11

* Add "Blessing" function.

## v1.10 2020-03-17

**INCONPARTIBLE CHANGES!!!**

* Delete `-A` (ACCS Processing) option.
* Processing ACCS automatically.
* ACCS Documents directory must have `.accs.yaml` file.
* Support `PureBuilder::ACCS::BLESS` Blessing proc in blessing script.
* Support `PureBuilder::ACCS::DEFINITIONS[:next]` and `PureBuilder::ACCS::DEFINITIONS[:prev]` procs in blessing script.
* Delete `pbsimply-accsindex.rb`
* Call blessing procs with `frontmatter, self`.
* Change timing to bless.

## v1.11 2020-03-17

Add JSON support.

* Add `dbstyle` in configuration.
* Blessing with external command.

## v1.11.1 2020-03-17

* Bless after all indexes stored.
* Find modify with any frontmatter modified.

## v1.11.2 2020-03-18

* Fix update checking on JSON db mode.
* rename `parse_frontmatter` to `proc_dir`.
* Fix sample `.pbsimply.yaml` file.

## v1.11.3 2020-03-18

* Fix bug: Skipped save to indexes DB when ACCS enabled.

## v1.11.4 2020-03-20

* Improve calculating.
* Some timing probrem are solved.

## v1.12 2020-03-22

**INCONPARTIBLE CHANGES!!!**

* Add automatic blessing methods.
* Change specific environment variables in pre/post plugins and blessing command.
* Use `Oj` instead of `JSON` if avilable.

## v1.13 2020-04-03

* Delete `blogmode` and `accs_order` support in `@index`
* Add default built-in `.accsindex.erb`, and add configurations `accs_across_category` and `accs_sort_by`.
* Add tutorial documents.
* Fix sample `.accsindex.erb`.
* Delete `util` (not worked).

## v1.14 2020-08-17

* Add `yaml` to `dbstyle`
* Add documents for PureBuilder Simply on Windows.

## v1.14.1 2021-03-03

* Enable YAML DBStyle

## v1.15 2022-01-01

* Support `-X` option
* Support separated metadata file
* Fix `ERb.new` arguments

## v2.0 2022-01-02

* Support multiple (RDoc, RDoc/Markdown, Kramdown, Redcarpet, CommonMarker) processors
* Fix bug when single mode
* Change filename
* Support RubyGems

## v2.1 2022-06-26 (dev)

* Add exporting article index feature
* Add `rst2html5` (docutils) support.
* Use tempdir for defaultfiles, frontmatter and current document.

## v2.2 2023-08-22 (dev)

**INCONPARTIBLE CHANGES!!!**

* Add Hooks feature
* Update single mode features
* *Use temporary directory for processing data instead of root directory*

## v3.0 2023-10-10

* Single mode improvement and bug fix
* Big refactoring
* Remove unused code
* Extend Hooks feature
* Find deleted article
* Add `auto_delete` option
* *Pre/Post plugins are now deprecated*
* Add `dest_path`, `normalized_docdir`, `normalized_docpathz` to frontmatter
* Fix `$pbsimply_indexes`, `$pbsimply_frontmatter` variable were not working
* Add `$pbsimply_working_dir` environment variable
* Fix `unsafe_load` problem in YAML docdb
* Support `RDoc` in `_docformat` frontmatter
* Update request Ruby version in README 2.3 to 3.0 (Actual required >=2.6 at least for endless range)

## v3.0.2 2023-10-15

* Fix detecting update
* Add configuration for detecting update.