#!/bin/env ruby

require 'yaml'
require 'erb'
require 'date'
require 'time'
require 'tmpdir'
require 'fileutils'
require 'optparse'
require 'digest/sha1'

# PureBuilder Simply Components
require 'pbsimply/docdb'
require 'pbsimply/docengine/base'
require 'pbsimply/prayer'
require 'pbsimply/plugger'
require 'pbsimply/hooks'
require 'pbsimply/frontmatter'
require 'pbsimply/accs'

class PBSimply
  include Prayer
  include Plugger
  include Frontmatter
  include ACCS

  # Use Oj as JSON library for frontmatter passing if possible.
  begin
    require 'oj'
    JSON_LIB = Oj
  rescue LoadError
    require 'json'
    JSON_LIB = JSON
  end

  ###############################################
  #               SETUP FUNCTIONS               #
  ###############################################

  # Load config file.
  def self.load_config
    config = nil
    begin
      File.open(".pbsimply.yaml") do |f|
        config = Psych.unsafe_load(f)
      end
    rescue
      abort "Failed to load config file (./.pbsimply.yaml)"
    end

    # Required values
    config["outdir"] or abort "Output directory is not set (outdir)."
    config["template"] ||= "./template.html"

    config
  end

  # initialize phase,
  def setup_config(dir)
    ENV["pbsimply_outdir"] = @config["outdir"]
    @docobject[:config] = @config

    if @singlemode
      outdir = [@config["outdir"], @dir.sub(%r:/[^/]*$:, "")].join("/")
    else
      outdir = [@config["outdir"], @dir].join("/")
    end

    # Format for Indexes database
    @db = case @config["dbstyle"]
    when "yaml"
      DocDB::YAML.new(dir)
    when "json"
      DocDB::JSON.new(dir)
    when "oj"
      DocDB::Oj.new(dir)
    when "marshal"
      DocDB::Marshal.new(dir)
    else
      DocDB::JSON.new(dir)
    end

    @frontmatter.merge!(@config["default_meta"]) if @config["default_meta"]

    # Merge ACCS Frontmatter
    if @accs_processing && @config["alt_frontmatter"]
      @frontmatter.merge!(@config["alt_frontmatter"])
    end

    unless File.exist? outdir
      STDERR.puts "destination directory is not exist. creating (only one step.)"
      FileUtils.mkdir_p outdir
    end
  end

  def initialize(config)
    @config = config
    @docobject = {}
    @this_time_processed = []

    # --metadata-file
    @frontmatter = {}

    @refresh = false # Force generate all documents.
    @skip_index = false # Don't register to index.
    @outfile = nil # Fixed output filename
    @add_meta = nil
    @accs = nil
    @accs_index = {}
    @now = Time.now
    @hooks = PBSimply::Hooks.new(self, @config)
  end

  # Process command-line
  def treat_cmdline(dir=nil)
    # Options definition.
    opts = OptionParser.new
    opts.on("-f", "--force-refresh") { @refresh = true }
    opts.on("-X", "--ignore-ext") { @ignore_ext = true }
    opts.on("-I", "--skip-index") { @skip_index = true }
    opts.on("-A", "--skip-accs") { @skip_accs = true }
    opts.on("-o FILE", "--output") {|v| @outfile = v }
    opts.on("-m FILE", "--additional-metafile") {|v| @add_meta = Psych.unsafe_load(File.read(v))}
    opts.parse!(ARGV)

    if File.exist?(".pbsimply-bless.rb")
      require "./.pbsimply-bless.rb"
    end

    # Set target directory.
    @dir = ARGV.shift unless dir
    @dir ||= "."
    ENV["pbsimply_subdir"] = @dir
  end

  # Load document index database (.indexes.${ext}).
  def load_index
    if @db.exist?
      @indexes = @db.load
    else
      @indexes = Hash.new
    end
    @docobject[:indexes] = @indexes
    ENV["pbsimply_indexes"] = @db.path
  end

  def target_file_extensions
    [".md"]
  end

  # Accessor reader.
  def doc
    @docobject
  end

  attr :indexes

  ###############################################
  #            PROCESSING FUNCTIONS             #
  ###############################################

  # Directory mode's main function.
  # Read Frontmatters from all documents and proc each documents.
  def proc_dir
    draft_articles = []
    target_docs = []
    @indexes_orig = {}
    STDERR.puts "in #{@dir}..."

    STDERR.puts "Checking Frontmatter..."
    Dir.foreach(@dir) do |filename|
      next if filename == "." || filename == ".." || filename == ".index.md"
      if filename =~ /^\./ || filename =~ /^draft-/
        draft_articles.push({
          article_filename: filename.sub(/^(?:\.|draft-)/, ""),
          filename: filename,
          source_file_path: File.join(@dir, filename)
        })
        next
      end

      if !@ignore_ext and not target_file_extensions.include? File.extname filename
        next
      end

      STDERR.puts "Checking frontmatter in #{filename}"
      frontmatter, pos = read_frontmatter(@dir, filename)
      frontmatter = @frontmatter.merge frontmatter
      frontmatter.merge!(@add_meta) if @add_meta

      if frontmatter["draft"]
        draft_articles.push({
          article_filename: filename,
          filename: filename,
          source_file_path: File.join(@dir, filename)
        })
        next
      end

      @indexes_orig[filename] = @indexes[filename]
      @indexes[filename] = frontmatter

      # Push to target documents without checking modification.
      target_docs.push([filename, frontmatter, pos])
    end
    ENV.delete("pbsimply_currentdoc")
    ENV.delete("pbsimply_filename")

    delete_turn_draft draft_articles

    proc_docs target_docs

    delete_missing

    # Save index.
    @db.dump(@indexes) unless @skip_index

    # ACCS processing
    if @accs && !target_docs.empty?
      process_accs
    end
  end

  def proc_docs target_docs
    # Exclude unchanged documents.
    if @indexes && @indexes_orig
      STDERR.puts "Checking modification..."
      target_docs.delete_if {|filename, frontmatter, pos| !check_modify(filename, frontmatter)}
    end

    # Modify frontmatter `BLESSING'
    target_docs.each do |filename, frontmatter, pos|
      STDERR.puts "Blessing #{filename}..."
      bless frontmatter
    end

    # Ready.
    STDERR.puts "Okay, Now ready. Process documents..."

    # Proccess documents
    target_docs.each do |filename, frontmatter, pos|
      ext = File.extname filename
      ENV["pbsimply_currentdoc"] = File.join(@workdir, "current_document#{ext}")
      ENV["pbsimply_filename"] = filename
      @index = frontmatter
      File.open(File.join(@dir, filename)) do |f|
        f.seek(pos)
        File.open(File.join(@workdir, "current_document#{ext}"), "w") {|fo| fo.write f.read}
      end

      STDERR.puts "Processing #{filename}"
      generate(@dir, filename, frontmatter)
    end
    
    # Call post plugins
    post_plugins

    # Call hooks
    @hooks.post.run({this_time_processed: @this_time_processed})
  end

  # Delete turn to draft article.
  def delete_turn_draft draft_articles
    STDERR.puts "Checking turn to draft..."
    draft_articles.each do |dah|
      df = dah[:article_filename]
      [df, (df + ".html"), File.basename(df, ".*"), (File.basename(df, ".*") + ".html")].each do |tfn|
        tfp = File.join(@config["outdir"], @dir, tfn)
        if File.file?(tfp)
          STDERR.puts "#{df} was turn to draft."
          @hooks.delete.run({target_file_path: tfp, source_file_path: dah[:source_file_path]})
          File.delete tfp if @config["auto_delete"]
        end
      end
      @indexes.delete df if @indexes[df]
    end
  end

  # Delete missing source
  def delete_missing
    return unless @indexes
    STDERR.puts "Checking missing article..."
    missing_keys = []
    @indexes.each do |k, v|
      next if !v["source_path"] || !v["dest_path"]
      unless File.exist? v["source_path"]
        STDERR.puts "#{k} is missing."
        missing_keys.push k
        @hooks.delete.run({target_file_path: v["dest_path"] ,source_file_path: v["source_path"]})
        File.delete v["dest_path"] if @config["auto_delete"]
      end
    end
    missing_keys.each {|k| @indexes.delete k }
  end

  # Run PureBuilder Simply.
  def main
    @hooks.load
    Dir.mktmpdir("pbsimply") do |dir|
      ENV["pbsimply_working_dir"] = dir
      @workdir ||= dir
      @workfile_frontmatter ||= File.join(@workdir, "pbsimply-frontmatter.json")
      ENV["pbsimply_frontmatter"] = @workfile_frontmatter
      @workfile_pandoc_defaultfiles ||= File.join(@workdir, "pbsimply-defaultfiles.yaml")
      # If target file is regular file, run as single mode.
      @singlemode = true if File.file?(@dir)

      # Check single file mode.
      if @singlemode
        # Single file mode
        if @dir =~ %r:(.*)/([^/]+):
          dir = $1
          filename = $2
        else
          dir = "."
          filename = @dir
        end
        @dir = dir
        setup_config(dir)

        load_index

        frontmatter, pos = read_frontmatter(dir, filename)
        frontmatter = @frontmatter.merge frontmatter
        @index = frontmatter

        proc_docs([[filename, frontmatter, pos]])

        if File.exist?(File.join(@dir, ".accs.yaml")) && !@accs_processing && !@skip_accs
          single_accs filename, frontmatter
        end
      else
        # Normal (directory) mode.
        setup_config(@dir)
        load_index

        @accs = true if File.exist?(File.join(@dir, ".accs.yaml"))

        proc_dir
      end
    end
  ensure
    @workdir = nil
    @workfile_frontmatter = nil
    @workfile_pandoc_defaultfiles = nil
  end

  def generate(dir, filename, frontmatter)
    print_fileproc_msg(filename) # at sub-class

    # Preparing and pre script.
    orig_filepath = [dir, filename].join("/")
    ext = File.extname(filename)
    procdoc = File.join(@workdir, "current_document#{ext}")

    pre_plugins(procdoc, frontmatter)
    @hooks.pre.run({procdoc: procdoc, frontmatter: frontmatter})

    doc = process_document(dir, filename, frontmatter, orig_filepath, ext, procdoc) # at sub-class

    ##### Post eRuby
    if @config["post_eruby"]
      STDERR.puts "Porcessing with eRuby."
      doc = ERB.new(doc, nil, "%<>").result(binding)
    end

    # Write out
    outpath = frontmatter["dest_path"]

    File.open(outpath, "w") do |f|
      f.write(doc)
    end

    # Hooks for processed document.
    @hooks.process.run({
      outpath: outpath,
      frontmatter: frontmatter,
      procdoc: procdoc
    })

    # Mark processed
    @this_time_processed.push({source: orig_filepath, dest: outpath, frontmatter: frontmatter})
  end

  ###############################################
  #      PRIVATE METHODS (treat document)       #
  ###############################################

  private

  # Check is the article modified? (or force update?)
  def check_modify(filename, frontmatter)
    modify = true
    index = @indexes_orig[filename]&.dup || {}

    case @config["detect_modification"]
    when "changes"
      # Use "changes"
      modify = false if frontmatter["changes"] == index["changes"]
    when "mtimesize"
      # Use mtime and file size.
      modify = false if frontmatter["_mtime"] <= (index["_last_proced"] || 0) && frontmatter["_size"] == index["_size"]
    else
      # Default method, use mtime.
      modify = false if frontmatter["_mtime"] <= (index["_last_proced"] || 0)
    end


    if modify
      STDERR.puts "#{filename} last modified at #{frontmatter["_mtime"]}, last processed at #{@indexes_orig[filename]&.[]("_last_proced") || 0}"
    else
      STDERR.puts "#{filename} is not modified."
    end

    frontmatter["_last_proced"] = @now.to_i
    frontmatter["last_update"] = @now.strftime("%Y-%m-%d %H:%M:%S")

    if @refresh
      # Refresh (force update) mode.
      true
    else
      modify
    end
  end
end
