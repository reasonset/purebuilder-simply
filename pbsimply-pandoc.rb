#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-

require 'yaml'
require 'erb'
require 'date'

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

    # Set target directory.
    @dir = ARGV.shift unless dir
    @dir ||= "."
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
      abort "Failed to load config file (.pbsimple.yaml)"
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

      if check_modify([@dir, filename], frontmatter)
        STDERR.puts "Processing #{filename}"
        lets_pandoc(@dir, filename)
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
      @pandoc_options = @pandoc_default_options.clone
      @dir = dir

      lets_pandoc(dir, filename)


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

  def post_plugins
    if File.directory?(".post_generate")

      ENV["pbsimply-indexes"] = [@dir, ".indexes.rbm"].join("/")
      STDERR.puts("Processing with post plugins")

      Dir.foreach(".post_generate") do |script_file|
        next if script_file =~ /^\./
        STDERR.puts "Running script: #{script_file}"
        @this_time_processed.each do |v|
          STDERR.puts "Processing #{v[:dest]} (from #{v[:source]})"
          filename = v[:dest]
          post_script_result = nil
          IO.popen(["perl", [".post_generate", script_file].join("/"), filename]) do |io|
            post_script_result = io.read
          end

          File.open(filename, "w") {|f| f.write post_script_result}
        end
      end
    end
  end

  private

  def read_frontmatter(dir, filename)
    @pandoc_options = @pandoc_default_options.clone
    frontmatter = nil

    case File.extname filename
    when ".md"

      # Load Markdown's YAML frontmatter.
      File.open([dir, filename].join("/")) do |f|
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

      File.open([dir, filename].join("/")) do |f|
        l = f.gets
        if l =~ /:[A-Za-z]+: .*/ #docinfo
          docinfo_lines = [l.chomp]

          # Read docinfo
          while(l = f.gets)
            break if l =~ /^\s*$/ # End of docinfo
            if l =~ /^\s+- / && (docinfo_lines.last.kind_of?(Array) || docinfo_lines.last =~ /^:.*?: +-/) # List items
              if docinfo_lines.last.kind_of?(String)
                docinfo_lines.last =~ /^:(.*?): +- *(.*)/
                docinfo_lines[-1] = [ [$1, $2] ]
              end
              docinfo_lines.last[1].push(l.sub(/^\s+- +/).chomp)
            elsif l =~ /^\s+/ # Continuous line
              docinfo_lines.last << " " + $'.chomp
            elsif l =~ /^:.*?: +.*/
              docinfo_lines.push l.chomp
            end
          end

          # Convert Hash.
          frontmatter = {}
          docinfo_lines.each do |i|
            if i.kind_of?(Array) #list
              # Array element
              frontmatter[i[0]] = i[1]
            elsif i =~ /^:author: .*[,;]/ #author
              # It work only pandoc style author (not Authors.)
              author = i.sub(/:author: /, "")
              if author.include?(";")
                author = author.split(/ *; */)
              elsif author.include?(",")
                author = author.split(/ *, */)
              end

              frontmatter["author"] = author
            elsif i =~ /^:(.*?): +(\d{4}-\d{2}-\d{2}[T ]\d{2}[0-9: T+-]*)$/ #datetime
              key = $1
              time = DateTime.parse($2)
              frontmatter[key] = time
            elsif i =~ /^:(.*?): +(\d{4}-\d{2}-\d{2}) *$/ #date
              key = $1
              time = Date.parse($2)
              frontmatter[key] = time
            elsif i =~ /^:(.*?): +/
              key = $1
              value = $'
              frontmatter[key] = value
            end
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
      end
    end

    return frontmatter
  end

  def check_modify(path, frontmatter)
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
  def lets_pandoc(dir, filename)
    STDERR.puts "#{filename} is going Pandoc."
    doc = nil

    # Add index values to commnadline meta.
    @index.each do |k,v|
      if v.kind_of?(Array)
        v.each do |i|
          @pandoc_options.push("-M")
          @pandoc_options.push("#{k}:#{i}")
        end
      else
        @pandoc_options.push("-M")
        @pandoc_options.push("#{k}:#{v}")
      end
    end

    # Go Pandoc
    filepath = [dir, filename].join("/")
    IO.popen((["pandoc"] + @pandoc_options + [ filepath ] )) do |io|
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
    outpath = [@config["outdir"], @dir, File.basename(filename, ".*")].join("/") + ".html"

    File.open(outpath, "w") do |f|
      f.write(doc)
    end

    # Mark processed
    @this_time_processed.push({source: filepath, dest: outpath})
  end

end

PureBuilder.new.main
