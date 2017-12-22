#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-

require 'yaml'
require 'erb'

class PureDoc
  def initialize(dir=nil)
    @docobject = {}
    @pandoc_default_options = ["-t", "html5", "-s"]

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
      next if filename =~ /^\./
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

      File.open([@dir, ".indexes.rbm"].join("/"), "w") do |f|
        Marshal.dump(@indexes, f)
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
        rescue
          next
        end
      end

    when ".rst"

      # Load ReST YAML that document begins comment and block is yaml.
      File.open([dir, filename].join("/")) do |f|
        l = f.gets
        next unless l && l.chomp == ".."

        lines = []

        while (l = f.gets)
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
      @pandoc_options.push("-M")
      @pandoc_options.push("#{k}:#{v}")
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
  end

end

PureDoc.new.main
