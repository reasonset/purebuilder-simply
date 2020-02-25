# v1.2 2018-02-07

* Support docinfo in ReST
* Skip if filename start with `draft-`
* Delete entry in indexes if not exist.

# v1.2.1 2018-02-21

* .accs_index.rbm is added index file list.
* Support Array metadata.

# v1.3 2018-05-20

* More suitable support for ReSTreuctured Text's docinfo.
* Commented out adding parsed metadata to commandline function.
  This feature is not necessary because Pandoc understand metadata right anyway.

# v1.4 2018-07-07

* Process temporary file instead of real document file.
* Support draft metadata. if draft is true, skip processing document.
* Add _docformat to doc metadata.
* Support $pbsimply_doc_frontmatter environment variable.
* Change $pbsimply-indexes to $pbsimply_indexes
* Add support Pre plugins.

# v1.4.1 2018-07-09

* Meta data give to pandoc with argument when ReST + docinfo for multiple element
* Add support docinfo term characters - and _.

# v1.4.2 2018-07-22

* Read .accsindex.erb on ACCS directory instead of the file on document root.

# v1.4.3 2018-08-02

* Keep plugin order.

# v1.4.4 2018-08-06

* Plugins can access subdirectory path with pbsimply_subdir environment variable.

# v1.4.5 2018-08-12

* Add Japanese README.

# v1.5 2018-08-14

* CHANGE LICENSE BSD 3-clause TO APACHE LICENSE 2.0
* Move document sample files to docroot-sample directory.
* New template and CSS files.
* Add JavaScript plugins.

# v1.6 2019-10-13

* Additional meta data support.
* Auto creating target directory.
* Force update mode.
* Support command line options.
* Bug fix: Post plugins didn't work in single mode.

# v1.6.1 2019-10-21

* More additional meta data support. (timestamp)
* Bug fix: wrong behavior on `-f` option.

# v1.7 2019-10-23

* Change test server's default port 80 to 8000.
* Converted timestamp uses dete if timestamp isn't defined.
* Add and rearrange sample docs.
* Directly execute plugins if it is executable, or call with script engine if known extension.

# v1.8 2020-02-25

* Change to use `defaults` and `metadata-file`. Now PureBuilder Simply requires Pandoc >= 2.8.
* Add metadata `timestamp_str`.
* Add some metadata about timestamp and encoded value.

NOW `pandoc_additional_options` IS MERGED INTO `defaults`. IT IS NOT COMMANDLINE OPTION.

# v1.8.1 2020-02-26

* Add commandline options (`-o`, `-m`, `-I`, `-A`)
* Fix ACCS system (to use `pbsimply-pandoc.rb` command).