#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-

require 'yaml'
require 'erb'
require 'date'
require 'fileutils'
require 'optparse'

begin
  require 'oj'
  JSON_LIB = Oj
rescue LoadError
  require 'json'
  JSON_LIB = JSON
end

class PureBuilder
  module ACCS
    DEFINITIONS = {}
  end

  # Abstruct super class.
  class DocDB
    def dump(object)
      File.open(File.join(@dir, ".indexes.#{@ext}"), "w") do |f|
        f.write @store_class.dump(object)
      end
    end

    def load
      File.open(File.join(@dir, ".indexes.#{@ext}"), "r") do |f|
        next @store_class.load(f)
    end
  end

    def exist?
      File.exist?(File.join(@dir, ".indexes.#{@ext}"))
    end

    def path
      File.join(@dir, ".indexes.#{@ext}")
    end

    def cmp_obj(frontmatter)
      @store_class.load(@store_class.dump(frontmatter))
    end

    class Marshal < DocDB
      def initialize(dir)
        @dir = dir
        @store_class = ::Marshal
        @ext = "rbm"
      end

      def cmp_obj(frontmatter)
        frontmatter.dup
      end
    end

    class JSON < DocDB
      def initialize(dir)
        @dir = dir
        @store_class = ::JSON
        @ext = "json"
      end
    end

    class Oj < DocDB::JSON
      def initialize(dir)
        require 'oj'
        @dir = dir
        @ext = "json"
        @store_class = ::Oj
      end
    end
  end
  

  POST_PROCESSORS = {
    ".rb" => "ruby",
    ".pl" => "perl",
    ".py" => "python",
    ".lua" => "lua",
    ".bash" => "bash",
    ".zsh" => "zsh",
    ".php" => "php",
    ".sed" => ["sed", ->(script, target) { ["-f", script, target] } ]
  }

  def initialize(dir=nil)
    @docobject = {}
    @this_time_processed = []

    # -d
    @pandoc_default_file = {
      "to" => "html5",
      "standalone" => true
    }
    # --metadata-file
    @frontmatter = {}

    @refresh = false # Force generate all documents.
    @skip_index = false # Don't register to index.
    @outfile = nil # Fixed output filename
    @add_meta = nil
    @accs = nil
    @accs_index = {}
    @now = Time.now

    # Options definition.
    opts = OptionParser.new
    opts.on("-f", "--force-refresh") { @refresh = true }
    opts.on("-I", "--skip-index") { @skip_index = true }
    opts.on("-o FILE", "--output") {|v| @outfile = v }
    opts.on("-m FILE", "--additional-metafile") {|v| @add_meta = YAML.load(File.read(v))}
    opts.parse!(ARGV)

    if File.exist?(".pbsimply-bless.rb")
      require "./.pbsimply-bless.rb"
    end

    # Set target directory.
    @dir = ARGV.shift unless dir
    @dir ||= "."
    ENV["pbsimply_subdir"] = @dir
  end

  def doc
    @docobject
  end

  attr :indexes

  # Load config file.
  def load_config(dir)
    begin
      File.open(".pbsimply.yaml") do |f|
        @config = YAML.load(f)
      end
    rescue
      abort "Failed to load config file (.pbsimply.yaml)"
    end

    # Required values
    @config["outdir"] or abort "Output directory is not set (outdir)."
    @config["template"] ||= "./template.html"

    ENV["pbsimply_outdir"] = @config["outdir"]

    @docobject[:config] = @config

    if @config["css"]
      if @config["css"].kind_of?(String)
        @pandoc_default_file["css"] = [@config["css"]]
      elsif @config["css"].kind_of?(Array)
        @pandoc_default_file["css"] = @config["css"]
      else
        abort "css in Config should be a String or an Array."
      end
    end

    if @config["toc"]
      @pandoc_default_file["toc"] = true
    end
    
    @pandoc_default_file["template"] = @config["template"]
    
    if Hash === @config["pandoc_additional_options"]
      @pandoc_default_file.merge! @config["pandoc_additional_options"]
    end
    
    if @singlemode
      outdir = [@config["outdir"], @dir.sub(%r:/[^/]*$:, "")].join("/")
    else
      outdir = [@config["outdir"], @dir].join("/")
    end
    
    # Format for Indexes database
    @db = case @config["dbstyle"]
    when "json"
      DocDB::JSON.new(dir)
    when "oj"
      DocDB::Oj.new(dir)
    else
      DocDB::Marshal.new(dir)
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

  # Load document index database (.indexes.${ext}).
  def load_index
    if @db.exist?
      @indexes = @db.load
    else
      @indexes = Hash.new
    end
    @docobject[:indexes] = @indexes
  end

  # Directory mode's main function.
  # Read Frontmatters from all documents and proc each documents.
  def proc_dir
    target_docs = []
    @indexes_orig = {}
    STDERR.puts "in #{@dir}..."

    STDERR.puts "Checking Frontmatter..."
    Dir.foreach(@dir) do |filename|
      next if filename == "." || filename == ".." 
      if filename =~ /^\./ || filename =~ /^draft-/
        if File.exist?(File.join(@config["outdir"], @dir, filename.sub(/^(?:\.|draft-)/, "").sub(/\.(?:md|rst)$/, ".html"))) && filename != ".index.md"
          STDERR.puts "#{filename} was turn to draft. deleting..."
          File.delete(File.join(@config["outdir"], @dir, filename.sub(/^(?:\.|draft-)/, "").sub(/\.(?:md|rst)$/, ".html")))
        end
        next
      end
      next unless File.file?([@dir, filename].join("/"))
      next unless %w:.md .rst:.include? File.extname filename
      STDERR.puts "Checking frontmatter in #{filename}"
      frontmatter, pos = read_frontmatter(@dir, filename)
      frontmatter = @frontmatter.merge frontmatter
      frontmatter.merge!(@add_meta) if @add_meta
      
      if frontmatter["draft"]
        @indexes.delete(filename) if @indexes[filename]
        if File.exist?(File.join(@config["outdir"], @dir, filename.sub(/\.(?:md|rst)$/, ".html")))
          STDERR.puts "#{filename} was turn to draft. deleting..."
          File.delete(File.join(@config["outdir"], @dir, filename.sub(/\.(?:md|rst)$/, ".html")))
        end
        next
      end

      @indexes_orig[filename] = @indexes[filename]
      @indexes[filename] = frontmatter

      # Push to target documents without checking modification.
      target_docs.push([filename, frontmatter, pos])
    end

    @db.dump(@indexes) unless @skip_index

    STDERR.puts "Blessing..."

    # Modify frontmatter
    target_docs.each do |filename, frontmatter, pos|
      if @config["bless_style"] == "cmd"
        bless_cmd(frontmatter)
      else
        bless_ruby(frontmatter)
      end  
    end

    STDERR.puts "Checking modification..."

    target_docs.delete_if {|filename, frontmatter, pos| !check_modify([@dir, filename], frontmatter)}

    STDERR.puts "Okay, Now ready. Let's Pandoc..."

    # Proccess documents
    target_docs.each do |filename, frontmatter, pos|
      ext = File.extname filename
      @index = frontmatter
      File.open(File.join(@dir, filename)) do |f|
        f.seek(pos)
        File.open(".current_document#{ext}", "w") {|fo| fo.write f.read}
      end

      STDERR.puts "Processing #{filename}"
      lets_pandoc(@dir, filename, frontmatter)
    end

    @db.dump(@indexes) unless @skip_index

    post_plugins

    # ACCS processing
    if @accs && !target_docs.empty?
      process_accs
    end
  end

  def main
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

      load_config(dir)
      load_index

      frontmatter, pos = read_frontmatter(dir, filename)
      frontmatter = @frontmatter.merge frontmatter
      check_modify([dir, filename], frontmatter)
      @index = frontmatter

      ext = File.extname filename
      File.open(File.join(dir, filename)) do |f|
        f.seek(pos)
        File.open(".current_document#{ext}", "w") {|fo| fo.write f.read}
      end      

      lets_pandoc(dir, filename, frontmatter)

      post_plugins(frontmatter)

    else
      # Normal (directory) mode.
      load_config(@dir)
      load_index

      @accs = true if File.exist?(File.join(@dir, ".accs.yaml"))
      
      # Check existing in indexes.
      @indexes.delete_if {|k,v| ! File.exist?([@dir, k].join("/")) }

      proc_dir

    end
  ensure
    File.delete ".pbsimply-defaultfiles.yaml" if File.exist?(".pbsimply-defaultfiles.yaml")
    File.delete ".pbsimply-frontmatter.json" if File.exist?(".pbsimply-frontmatter.json")
    File.delete ".current_document.md" if File.exist?(".current_document.md")
    File.delete ".current_document.rst" if File.exist?(".current_document.rst")
    File.delete ".pbsimply-frontmatter.yaml" if File.exist?(".pbsimply-frontmatter.yaml")
  end

  def pre_plugins(procdoc, frontmatter)
    if File.directory?(".pre_generate")
      STDERR.puts("Processing with pre plugins")
      script_file = File.join(".pre_generate", script_file)
      Dir.entries(".pre_generate").sort.each do |script_file|
        next if script_file =~ /^\./
        STDERR.puts "Running script: #{File.basename script_file}"
        pre_script_result = nil
        script_cmdline = case
        when File.executable?(script_file)
          [script_file, procdoc]
        when POST_PROCESSORS[File.extname(script_file)]
          [POST_PROCESSORS[File.extname(script_file)], script_file, procdoc]
        else
          ["perl", script_file, procdoc]
        end
        IO.popen({"pbsimply_doc_frontmatter" => YAML.dump(frontmatter)}, script_cmdline) do |io|
          pre_script_result = io.read
        end
        File.open(procdoc, "w") {|f| f.write pre_script_result}
      end
    end
  end

  def post_plugins(frontmatter=nil)
    if File.directory?(".post_generate")

      STDERR.puts("Processing with post plugins")

      @this_time_processed.each do |v|
        STDERR.puts "Processing #{v[:dest]} (from #{v[:source]})"
        procdoc = v[:dest]
        frontmatter ||= @indexes[File.basename v[:source]]
        File.open(".pbsimply-frontmatter.json", "w") {|f| f.write JSON_LIB.dump(frontmatter)}
        Dir.entries(".post_generate").sort.each do |script_file|
          next if script_file =~ /^\./
          STDERR.puts "Running script: #{script_file}"
          script_file = File.join(".post_generate", script_file)
          post_script_result = nil
          script_cmdline = case
          when File.executable?(script_file)
            [script_file, procdoc]
          when POST_PROCESSORS[File.extname(script_file)]
            [POST_PROCESSORS[File.extname(script_file)], script_file, procdoc]
          else
            ["perl", script_file, procdoc]
          end
          IO.popen({"pbsimply_frontmatter" => ".pbsimply-frontmatter.json", "pbsimply_indexes" => @db.path}, script_cmdline) do |io| 
            post_script_result = io.read
          end

          File.open(procdoc, "w") {|f| f.write post_script_result}
        end
      end
    end
  end

  private

  # Turn on ACCS processing mode.
  def accsmode
    @accs_processing = true
    @singlemode = true
    @skip_index = true
  end

  # Read Frontmatter from the document.
  # This method returns frontmatter, pos.
  # pos means position at end of Frontmatter on the file.
  def read_frontmatter(dir, filename)
    frontmatter = nil
    pos = nil

    case File.extname filename
    when ".md"

      # Load Markdown's YAML frontmatter.
      File.open(File.join(dir, filename)) do |f|
        l = f.gets
        next unless l && l.chomp == "---"

        lines = []

        while l = f.gets
          break if l.nil?

          break if  l.chomp == "---"
          lines.push l
        end

        next if f.eof?

        begin
          frontmatter = YAML.load(lines.join)
        rescue => e
          STDERR.puts "!CRITICAL: Cannot parse frontmatter."
          raise e
        end

        pos = f.pos
      end

    when ".rst"
      # ReSTRUCTURED Text

      File.open(File.join(dir, filename)) do |f|
        l = f.gets
        if l =~ /:([A-Za-z_-]+): (.*)/ #docinfo
          frontmatter = { $1 => [$2.chomp] }
          last_key = $1

          # Read docinfo
          while(l = f.gets)
            break if l =~ /^\s*$/ # End of docinfo
            if l =~ /^\s+/ # Continuous line
              docinfo_lines.last.push($'.chomp)
            elsif l =~ /:([A-Za-z_-]+): (.*)/
              frontmatter[$1] = [$2.chomp]
              last_key = $1
            end
          end

          # Treat docinfo lines
          frontmatter.each do |k,v|
            v = v.join(" ")
            #if((k == "author" || k == "authors") && v.include?(";")) # Multiple authors.
            if(v.include?(";")) # Multiple element.
              v = v.split(/\s*;\s*/)

            elsif k == "date" # Date?
              # Datetime?
              if v =~ /[0-2][0-9]:[0-6][0-9]/
                v = DateTime.parse(v)
              else
                v = Date.parse(v)
              end
            elsif v == "yes" || v == "true"
              v = true
            else # Simple String.
              nil # keep v
            end

            frontmatter[k] = v
          end

        elsif l && l.chomp == ".." #YAML
          # Load ReST YAML that document begins comment and block is yaml.
          lines = []

          while(l = f.gets)
            if(l !~ /^\s*$/ .. l =~ /^\s*$/)
              if l=~ /^\s*$/
                break
              else
                lines.push l
              end
            end
          end
          next if f.eof?


          # Rescue for failed to read YAML.
          begin
            frontmatter = YAML.load(lines.map {|i| i.sub(/^\s*/, "") }.join)
          rescue
            STDERR.puts "Error in parsing ReST YAML frontmatter (#{$!})"
            next
          end
        else
          next
        end

        pos = f.pos

      end
    end

    abort "This document has no frontmatter" unless frontmatter
    abort "This document has no title." unless frontmatter["title"]


    ### Additional meta values. ###
    frontmatter["source_directory"] = dir # Source Directory
    frontmatter["source_filename"] = filename # Source Filename
    frontmatter["source_path"] = File.join(dir, filename) # Source Path
    # URL in site.
    this_url = (File.join(dir, filename)).sub(/^[\.\/]*/) { @config["self_url_prefix"] || "/" }.sub(/\.[a-zA-Z0-9]+$/, ".html")
    frontmatter["page_url"] = this_url
    # URL in site with URI encode.
    frontmatter["page_url_encoded"] = ERB::Util.url_encode(this_url)
    frontmatter["page_url_encoded_external"] = ERB::Util.url_encode((File.join(dir, filename)).sub(/^[\.\/]*/) { @config["self_url_external_prefix"] || "/" }.sub(/\.[a-zA-Z0-9]+$/, ".html"))
    frontmatter["page_html_escaped"] = ERB::Util.html_escape(this_url)
    frontmatter["page_html_escaped_external"] = ERB::Util.html_escape((File.join(dir, filename)).sub(/^[\.\/]*/) { @config["self_url_external_prefix"] || "/" }.sub(/\.[a-zA-Z0-9]+$/, ".html"))
    # Title with URL Encoded.
    frontmatter["title_encoded"] = ERB::Util.url_encode(frontmatter["title"])
    frontmatter["title_html_escaped"] = ERB::Util.html_escape(frontmatter["title"])
    fts = frontmatter["timestamp"] 
    fts = fts.to_datetime if Time === fts
    if DateTime === fts
      frontmatter["timestamp_xmlschema"] = fts.xmlschema
      frontmatter["timestamp_jplocal"] = fts.strftime('%Y年%m月%d日 %H時%M分%S秒')
      frontmatter["timestamp_rubytimestr"] = fts.strftime('%a %b %d %H:%M:%S %Z %Y')
      frontmatter["timestamp_str"] = fts.strftime("%Y-%m-%d %H:%M:%S %Z")
    elsif Date === fts
      frontmatter["timestamp_xmlschema"] = fts.xmlschema
      frontmatter["timestamp_jplocal"] = fts.strftime('%Y年%m月%d日')
      frontmatter["timestamp_rubytimestr"] = fts.strftime('%a %b %d')
      frontmatter["timestamp_str"] = fts.strftime("%Y-%m-%d")
    elsif Date === frontmatter["Date"]
      fts = frontmatter["Date"]
      frontmatter["timestamp_xmlschema"] = fts.xmlschema
      frontmatter["timestamp_jplocal"] = fts.strftime('%Y年%m月%d日')
      frontmatter["timestamp_rubytimestr"] = fts.strftime('%a %b %d')
      frontmatter["timestamp_str"] = fts.strftime("%Y-%m-%d")
    end

    fsize = FileTest.size(File.join(dir, filename))
    mtime = File.mtime(File.join(dir, filename)).to_i

    frontmatter["_filename"] ||= filename
    frontmatter["pagetype"] ||= "post"

    frontmatter["_size"] = fsize
    frontmatter["_mtime"] = mtime
    frontmatter["_last_proced"] = @now.to_i
    
    if File.extname(filename) == ".md"
      frontmatter["_docformat"] = "Markdown"
    elsif File.extname(filename) == ".rst" || File.extname(filename) == ".rest"
      frontmatter["_docformat"] = "ReST"
    end

    frontmatter["date"] ||= now.strftime("%Y-%m-%d %H:%M:%S")

    return frontmatter, pos
  end

  # Check is the article modified? (or force update?)
  def check_modify(path, frontmatter)
    modify = true
    index = @indexes_orig[path[1]].dup || {}
    frontmatter = @db.cmp_obj(frontmatter)
    index.delete("_last_proced")
    frontmatter.delete("_last_proced")

    if index == frontmatter
      STDERR.puts "#{path[1]} is not modified."
      modify = false
    else
      STDERR.puts "#{path[1]} last modified at #{frontmatter["_mtime"]}, last processed at #{@indexes_orig[path[1]]&.[]("_last_proced") || 0}"
      frontmatter["last_update"] = @now.strftime("%Y-%m-%d %H:%M:%S")
    end

    if @refresh
      # Refresh (force update) mode.
      true
    else
      modify
    end
  end

  def bless_ruby(frontmatter)
    # BLESSING (Always)
    if PureBuilder.const_defined?(:BLESS) && Proc === PureBuilder::BLESS
      begin
        PureBuilder::BLESS.(frontmatter, self)
      rescue
        STDERR.puts "*** BLESSING PROC ERROR ***"
        raise
      end
    end

    # BLESSING (ACCS)
    if @accs && PureBuilder::ACCS.const_defined?(:BLESS) && Proc === PureBuilder::ACCS::BLESS
      begin
        PureBuilder::ACCS::BLESS.(frontmatter, self)
      rescue
        STDERR.puts "*** ACCS BLESSING PROC ERROR ***"
        raise
      end
    end

    # ACCS DEFINITIONS
    if @accs
      if Proc === PureBuilder::ACCS::DEFINITIONS[:next]
        i = PureBuilder::ACCS::DEFINITIONS[:next].call(frontmatter, self)
        frontmatter["next_article"] = i if i
      end
      if Proc === PureBuilder::ACCS::DEFINITIONS[:prev]
        i = PureBuilder::ACCS::DEFINITIONS[:prev].call(frontmatter, self)
        frontmatter["prev_article"] = i if i
      end
    end

    autobless(frontmatter)
  end

  def bless_cmd(frontmatter)
    File.open(".pbsimply-frontmatter.json", "w") {|f| f.write JSON_LIB.dump(frontmatter) }
    # BLESSING (Always)
    if @config["bless_cmd"]
      (Array === @config["bless_cmd"] ? system(*@config["bless_cmd"]) : system(@config["bless_cmd"]) ) or abort "*** BLESS COMMAND RETURNS NON-ZERO STATUS"
    end
    # BLESSING (ACCS)
    if @config["bless_accscmd"]
      (Array === @config["bless_accscmd"] ? system({"pbsimply_frontmatter" => ".pbsimply-frontmatter.json", "pbsimply_indexes" => @db.path}, *@config["bless_accscmd"]) : system({"pbsimply_frontmatter" => ".pbsimply-frontmatter.json", "pbsimply_indexes" => @db.path}, @config["bless_accscmd"]) ) or abort "*** BLESS COMMAND RETURNS NON-ZERO STATUS"
    end
    mod_frontmatter = JSON.load(File.read(".pbsimply-frontmatter.json"))
    frontmatter.replace(mod_frontmatter)

    autobless(frontmatter)
  end

  # Blessing automatic method with configuration.
  def autobless(frontmatter)
    catch(:accs_rel) do
      # find Next/Prev page on accs
      if @accs && @config["blessmethod_accs_rel"]
        # Preparing. Run at once.
        if !@article_order
          @rev_article_order_index = {}

          case @config["blessmethod_accs_rel"]
          when "numbering"
            @article_order = @indexes.to_a.sort_by {|i| i[1]["_filename"].to_i }
          when "date"
            begin
              @article_order = @indexes.to_a.sort_by {|i| i[1]["date"]}
            rescue
              abort "*** Automatic Blessing Method Error: Maybe some article have no date."
            end
          when "timestamp"
            begin
              @article_order = @indexes.to_a.sort_by {|i| i[1]["timestamp"]}
            rescue
              abort "*** Automatic Blessing Method Error: Maybe some article have no timetsamp."
            end
          when "lexical"
            @article_order = @indexes.to_a.sort_by {|i| i[1]["_filename"]}
          end
          @article_order.each_with_index {|x,i| @rev_article_order_index[x[0]] = i }
        end

        throw(:accs_rel) unless index = @rev_article_order_index[frontmatter["_filename"]]
        if @article_order[index + 1]
          frontmatter["next_article"] = {"url" => @article_order[index + 1][1]["page_url"],
                                         "title" => @article_order[index + 1][1]["title"]}
        end
        if index > 0
          frontmatter["prev_article"] = {"url" => @article_order[index - 1][1]["page_url"],
                                         "title" => @article_order[index - 1][1]["title"]}
        end
      end
    end
  end

  # Invoke pandoc, parse and format and write out.
  def lets_pandoc(dir, filename, frontmatter)
    STDERR.puts "#{filename} is going Pandoc."
    doc = nil

    # Preparing and pre script.
    orig_filepath = [dir, filename].join("/")
    ext = File.extname(filename)
    procdoc = sprintf(".current_document%s", ext)
    pre_plugins(procdoc, frontmatter)

    File.open(".pbsimply-defaultfiles.yaml", "w") {|f| YAML.dump(@pandoc_default_file, f)}
    File.open(".pbsimply-frontmatter.yaml", "w") {|f| YAML.dump(frontmatter, f)}

    # Go Pandoc
    IO.popen((["pandoc"] + ["-d", ".pbsimply-defaultfiles.yaml", "--metadata-file", ".pbsimply-frontmatter.yaml", "-M", "title:#{frontmatter["title"]}"] + [ procdoc ] )) do |io|
      doc = io.read
    end
    
    # Abort if pandoc returns non-zero status
    if $?.exitstatus != 0
      abort "Pandoc returns exit code #{$?.exitstatus}"
    end

    ##### Post eRuby
    if @config["post_eruby"]
      STDERR.puts "Porcessing with eRuby."
      doc = ERB.new(doc, nil, "%<>").result(binding)
    end

    # Write out
    outpath = case
    when @outfile
      @outfile
    when @accs_processing
      File.join(@config["outdir"], @dir, "index") + ".html"
    else
      File.join(@config["outdir"], @dir, File.basename(filename, ".*")) + ".html"
    end

    File.open(outpath, "w") do |f|
      f.write(doc)
    end

    # Mark processed
    @this_time_processed.push({source: orig_filepath, dest: outpath})
  end

  # letsaccs
  #
  # This method called on the assumption that processed all documents and run as directory mode.
  def process_accs
    STDERR.puts "Processing ACCS index..."
    if File.exist?(File.join(@dir, ".accsindex.erb"))
      erbtemplate = File.read(File.join(@dir, ".accsindex.erb"))
    elsif File.exist?(".accsindex.erb")
      erbtemplate = File.read(".accsindex.erb")
    else
      abort "No .accesindex.erb"
    end

    # Get infomation
    @accs_index = YAML.load(File.read([@dir, ".accs.yaml"].join("/")))

    @accs_index["title"] ||= (@config["accs_index_title"] || "Index")
    @accs_index["date"] ||= Time.now.strftime("%Y-%m-%d")
    @accs_index["pagetype"] = "accs_index"

    @index = @frontmatter.merge @accs_index

    doc = ERB.new(erbtemplate, nil, "%<>").result(binding)
    File.open(File.join(@dir, ".index.md"), "w") do |f|
      f.write doc
    end

    accsmode
    @dir = File.join(@dir, ".index.md")
    main
  end
end

PureBuilder.new.main
