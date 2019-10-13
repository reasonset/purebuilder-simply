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
    @pandoc_default_options = ["-t", "html5", "-s"]
    @this_time_processed = []
    @extra_meta_format = false # Pandoc inunderstandable metadata format is used.
    @processing_document = ".#{$$}.pbsimply-processing"


    # Options definition.
    opts = OptionParser.new
    opts.on("-f") { @refresh = true }
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
        @pandoc_default_options.concat ["-c", @config["css"]]
      elsif @config["css"].kind_of?(Array)
        @config["css"].each do |i|
          @pandoc_default_options.concat ["-c", i]
        end
      end
    end

    if @config["toc"]
      @pandoc_default_options.push "--toc"
    end

    @pandoc_default_options.push "--template"
    @pandoc_default_options.push @config["template"]

    if @config["pandoc_additional_options"]
      @pandoc_default_options.concat @config["pandoc_additional_options"]
    end

    if @singlemode
      outdir = [@config["outdir"], @dir.sub(%r:/[^/]*$:, "")].join("/")
    else
      outdir = [@config["outdir"], @dir].join("/")
    end

    unless File.exist? outdir
      STDERR.puts "destination directory is not exist. creating (only one step.)"
      Dir.mkdir outdir
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
      frontmatter = read_frontmatter(@dir, filename)
      next if frontmatter["draft"]

      if check_modify([@dir, filename], frontmatter)
        STDERR.puts "Processing #{filename}"
        lets_pandoc(@dir, filename, frontmatter)
      end
    end
  end

  def main
    @singlemode = true if File.file?(@dir)
    load_config
    load_index

    # Check single file mode.
    if @singlemode
      # Single file mode
      if @dir =~ %r:(.*)/([^/]+):
        dir = $1
        filename = $2
      else
        dir = "."
        filename = $2
      end
      @dir = dir

      lets_pandoc(dir, filename, read_frontmatter(dir, filename))

      post_plugins

    else
      # Normal (directory) mode.
      parse_frontmatter

      # Check existing in indexes.
      @indexes.delete_if {|k,v| ! File.exist?([@dir, k].join("/")) }

      File.open([@dir, ".indexes.rbm"].join("/"), "w") do |f|
        Marshal.dump(@indexes, f)
      end

      post_plugins

    end
  end

  def pre_plugins(procdoc, frontmatter)
    if File.directory?(".pre_generate")
      STDERR.puts("Processing with pre plugins")
      Dir.entries(".pre_generate").sort.each do |script_file|
        next if script_file =~ /^\./
        STDERR.puts "Running script: #{script_file}"
        pre_script_result = nil
        IO.popen({"pbsimply_doc_frontmatter" => YAML.dump(frontmatter)}, ["perl", [".pre_generate", script_file].join("/"), procdoc]) do |io|
          pre_script_result = io.read
        end
        File.open(procdoc, "w") {|f| f.write pre_script_result}
      end
    end
  end

  def post_plugins
    if File.directory?(".post_generate")

      ENV["pbsimply_indexes"] = [@dir, ".indexes.rbm"].join("/")
      STDERR.puts("Processing with post plugins")

      indexes = nil
      File.open(ENV["pbsimply_indexes"]) {|f| indexes = Marshal.load(f) }

      Dir.entries(".post_generate").sort.each do |script_file|
        next if script_file =~ /^\./
        STDERR.puts "Running script: #{script_file}"
        @this_time_processed.each do |v|
          STDERR.puts "Processing #{v[:dest]} (from #{v[:source]})"
          filename = v[:dest]
          post_script_result = nil
          IO.popen({"pbsimply_doc_frontmatter" => YAML.dump(indexes[File.basename v[:source]])}, ["perl", [".post_generate", script_file].join("/"), filename], "r") do |io|
            post_script_result = io.read
          end

          File.open(filename, "w") {|f| f.write post_script_result}
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
      end

    when ".rst"
      # ReSTRUCTURED Text

      File.open(File.join(dir, filename)) do |f|
        l = f.gets
        if l =~ /:([A-Za-z_-]+): (.*)/ #docinfo
          @extra_meta_format = true # ReST docinfo is supported but there is some gritch.
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
              STDERR.puts v.inspect
              v = v.split(/\s*;\s*/)

            elsif k == "date" # Date?
              # Datetime?
              if v =~ /[0-2][0-9]:[0-6][0-9]/
                v = DateTime.parse(v)
              else
                v = Date.parse(v)
              end
            else # Simple String.
              nil # keep v
            end

            frontmatter[k] = v
          end

        elsif l && l.chomp == ".." #YAML
          # Load ReST YAML that document begins comment and block is yaml.
          @extra_meta_format = true # ReST + YAML is not supported by Pandoc.
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
      end
    end

    return frontmatter
  end

  def check_modify(path, frontmatter)
    return true if @refresh # Refresh (force update) mode.
    modify = true

    index = @indexes[path[1]] || {}
    fsize = FileTest.size(path.join("/"))
    mtime = File.mtime(path.join("/")).to_i

    default_infomation = {
      "_filename" => path[1],
      "pagetype" => "post"
    }

    now = Time.now
    current_infomation = {
      "_size" => fsize,
      "_mtime" => mtime,
      "_last_proced" => now.to_i
    }

    if path =~ /\.md$/
      current_infomation["_docformat"] = "Markdown"
    elsif path =~ /\.rst$/ || path =~ /\.rest$/
      current_infomation["_docformat"] = "ReST"
    end

    if index && index["_size"] == fsize && (current_infomation["_mtime"] < index["_last_proced"] || index["_mtime"] == current_infomation["_mtime"])
      STDERR.puts "#{path[1]} is not modified."
      modify = false
    else
      STDERR.puts "#{path[1]} last modified at #{current_infomation["_mtime"]}, last processed at #{index["_last_proced"] || 0}"
      current_infomation["last_update"] = now.strftime("%Y-%m-%d %H:%M:%S")
    end


    @indexes[path[1]] = default_infomation.merge(index || {}).merge(frontmatter || {}).merge(current_infomation)
    @indexes[path[1]]["date"] ||= now.strftime("%Y-%m-%d %H:%M:%S")
    @index = @indexes[path[1]]

    modify
  end

  # Invoke pandoc, parse and format and write out.
  def lets_pandoc(dir, filename, frontmatter)
    STDERR.puts "#{filename} is going Pandoc."
    doc = nil

    pandoc_options = @pandoc_default_options.clone

    # Add index values to commnadline meta.
    if @extra_meta_format # Only Original style metadata.
      @index.each do |k,v|
        if v.kind_of?(Array)
          v.each do |i|
            pandoc_options.push("-M")
            pandoc_options.push("#{k}:#{i}")
          end
        else
          pandoc_options.push("-M")
          pandoc_options.push("#{k}:#{v}")
        end
      end
    end

    ### Additional meta values. ###
    # Source Directory
    pandoc_options.push("-M")
    pandoc_options.push(sprintf('%s:%s', "source_directory", dir))
    # Source Filename
    pandoc_options.push("-M")
    pandoc_options.push(sprintf('%s:%s', "source_filename", filename))
    # Source Path
    pandoc_options.push("-M")
    pandoc_options.push(sprintf('%s:%s', "source_path", File.join(dir, filename)))
    # URL in site.
    this_url = (File.join(dir, filename)).sub(/^[\.\/]*/) { @config["self_url_prefix"] || "/" }.sub(/\.[a-zA-Z0-9]+$/, ".html")
    pandoc_options.push("-M")
    pandoc_options.push(sprintf('%s:%s', "page_url", this_url))
    # URL in site with URI encode.
    pandoc_options.push("-M")
    pandoc_options.push(sprintf('%s:%s', "page_url_encoded", ERB::Util.url_encode(this_url)))
    pandoc_options.push("-M")
    pandoc_options.push(sprintf('%s:%s', "page_url_encoded_external", ERB::Util.url_encode((File.join(dir, filename)).sub(/^[\.\/]*/) { @config["self_url_external_prefix"] || "/" }.sub(/\.[a-zA-Z0-9]+$/, ".html"))))
    # Title with URL Encoded.
    if frontmatter["title"]
      pandoc_options.push("-M")
      pandoc_options.push(sprintf('%s:%s', "title_encoded", ERB::Util.url_encode(frontmatter["title"])))  
    end

    # Preparing and pre script.
    orig_filepath = [dir, filename].join("/")
    procdoc = "#{@processing_document}.#{File.extname(filename)}"
    ::FileUtils.cp orig_filepath, procdoc
    pre_plugins(procdoc, frontmatter)

    # Go Pandoc
    IO.popen((["pandoc"] + pandoc_options + [ procdoc ] )) do |io|
      doc = io.read
    end

    if File.exist?(procdoc)
      File.delete procdoc
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
    outpath = [@config["outdir"], @dir, File.basename(filename, ".*")].join("/") + ".html"
    unless File.exist?(File.dirname(outpath))
      FileUtils.mkdir_p(File.dirname(outpath))
    end

    File.open(outpath, "w") do |f|
      f.write(doc)
    end

    # Mark processed
    @this_time_processed.push({source: orig_filepath, dest: outpath})
  end

end

PureBuilder.new.main
