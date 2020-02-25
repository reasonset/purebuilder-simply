#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-

require 'yaml'
require 'erb'
require 'date'
require 'fileutils'
require 'optparse'

class PureBuilder
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
    
    # Options definition.
    opts = OptionParser.new
    opts.on("-f", "--force-refresh") { @refresh = true }
    opts.on("-I", "--skip-index") { @skip_index = true }
    opts.on("-o FILE", "--output") {|v| @outfile = v }
    opts.on("-m FILE", "--additional-metafile") {|v| @add_meta = YAML.load(File.read(v))}
    opts.on("-A", "--accs") { 
      @accs = true
      @singlemode = true
      @skip_index = true
    }
    opts.parse!(ARGV)

    # Set target directory.
    @dir = ARGV.shift unless dir
    @dir ||= "."
    ENV["pbsimply_subdir"] = @dir
  end

  def doc
    @docobject
  end

  def load_config
    # Load config file.
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

    @frontmatter.merge!(@config["default_meta"]) if @config["default_meta"]

    # Merge ACCS Frontmatter
    if @accs && @config["alt_frontmatter"]
      @frontmatter.merge!(@config["alt_frontmatter"])
    end

    unless File.exist? outdir
      STDERR.puts "destination directory is not exist. creating (only one step.)"
      FileUtils.mkdir_p outdir
    end
  end

  def load_index
    # Load document index.
    if File.exist?([@dir, ".indexes.rbm"].join("/"))
      File.open([@dir, ".indexes.rbm"].join("/")) do |f|
        @indexes = Marshal.load(f)
      end
    else
      @indexes = Hash.new
    end
    @docobject[:indexes] = @indexes
  end

  def parse_frontmatter
    STDERR.puts "in #{@dir}..."
    Dir.foreach(@dir) do |filename|
      next if filename =~ /^\./ || filename =~ /^draft-/
      next unless File.file?([@dir, filename].join("/"))
      next unless %w:.md .rst:.include? File.extname filename
      STDERR.puts "Checking frontmatter in #{filename}"
      frontmatter = @frontmatter.merge read_frontmatter(@dir, filename)
      frontmatter.merge!(@add_meta) if @add_meta
      next if frontmatter["draft"]

      if check_modify([@dir, filename], frontmatter)
        STDERR.puts "Processing #{filename}"
        lets_pandoc(@dir, filename, frontmatter)
      end
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

      load_config
      load_index

      frontmatter = read_frontmatter(dir, filename)

      lets_pandoc(dir, filename, frontmatter)

      post_plugins(frontmatter)

    else
      # Normal (directory) mode.
      load_config
      load_index
      parse_frontmatter

      # Check existing in indexes.
      @indexes.delete_if {|k,v| ! File.exist?([@dir, k].join("/")) }

      unless @skip_index
        File.open([@dir, ".indexes.rbm"].join("/"), "w") do |f|
          Marshal.dump(@indexes, f)
        end
      end

      post_plugins

    end
  ensure
    File.delete ".pbsimply-defaultfiles.yaml" if File.exist?(".pbsimply-defaultfiles.yaml")
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

      ENV["pbsimply_indexes"] = [@dir, ".indexes.rbm"].join("/")
      STDERR.puts("Processing with post plugins")

      indexes = nil
      File.open(ENV["pbsimply_indexes"]) {|f| indexes = Marshal.load(f) }

      Dir.entries(".post_generate").sort.each do |script_file|
        next if script_file =~ /^\./
        STDERR.puts "Running script: #{script_file}"
        script_file = File.join(".post_generate", script_file)
        @this_time_processed.each do |v|
          STDERR.puts "Processing #{v[:dest]} (from #{v[:source]})"
          procdoc = v[:dest]
          post_script_result = nil
          script_cmdline = case
          when File.executable?(script_file)
            [script_file, procdoc]
          when POST_PROCESSORS[File.extname(script_file)]
            [POST_PROCESSORS[File.extname(script_file)], script_file, procdoc]
          else
            ["perl", script_file, procdoc]
          end
          IO.popen({"pbsimply_doc_frontmatter" => YAML.dump(frontmatter || indexes[File.basename v[:source]])}, script_cmdline) do |io|  
            post_script_result = io.read
          end

          File.open(procdoc, "w") {|f| f.write post_script_result}
        end
      end
    end
  end

  private

  def read_frontmatter(dir, filename)
    frontmatter = nil

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

        # Output document
        File.open(".current_document.md", "w") {|fo| fo.write f.read}
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

        # Output document
        File.open(".current_document.rst", "w") do |fo|
          fo.write f.read
        end
      end
    end

    abort "This document has no frontmatter" unless frontmatter
    abort "This document has no title." unless frontmatter["title"]

    return frontmatter
  end

  def check_modify(path, frontmatter)
    modify = true

    index = @indexes[path[1]] || {}
    fsize = FileTest.size(path.join("/"))
    mtime = File.mtime(path.join("/")).to_i

    frontmatter["_filename"] ||= path[1]
    frontmatter["pagetype"] ||= "post"

    now = Time.now
    current_infomation = {
      "_size" => fsize,
      "_mtime" => mtime,
      "_last_proced" => now.to_i
    }

    if path[1] =~ /\.md$/
      current_infomation["_docformat"] = "Markdown"
    elsif path[1] =~ /\.rst$/ || path[1] =~ /\.rest$/
      current_infomation["_docformat"] = "ReST"
    end

    if index && index["_size"] == fsize && (current_infomation["_mtime"] < index["_last_proced"] || index["_mtime"] == current_infomation["_mtime"])
      STDERR.puts "#{path[1]} is not modified."
      modify = false
    else
      STDERR.puts "#{path[1]} last modified at #{current_infomation["_mtime"]}, last processed at #{index["_last_proced"] || 0}"
      current_infomation["last_update"] = now.strftime("%Y-%m-%d %H:%M:%S")
    end

    frontmatter.merge!(current_infomation)
    frontmatter["date"] ||= now.strftime("%Y-%m-%d %H:%M:%S")

    @indexes[path[1]] = frontmatter
    @index = @indexes[path[1]]

    if @refresh
      # Refresh (force update) mode.
      true
    else
      modify
    end
  end

  # Invoke pandoc, parse and format and write out.
  def lets_pandoc(dir, filename, frontmatter)
    STDERR.puts "#{filename} is going Pandoc."
    doc = nil

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
    
    File.delete procdoc if File.exist?(procdoc)
    File.delete ".pbsimply-frontmatter.yaml" if File.exist?(".pbsimply-frontmatter.yaml")

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
    when @accs
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

end

PureBuilder.new.main
