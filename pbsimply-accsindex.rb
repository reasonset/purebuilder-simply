#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-

require 'yaml'
require 'erb'
require 'date'

pbaccs = Object.new

class << pbaccs

  def letsaccs

    @dir = ARGV.shift
    @dir ||= "."

    erbtemplate = File.read(".accsindex.erb")

    begin
      File.open(".pbsimply.yaml") do |f|
        @config = YAML.load(f)
      end
    rescue
      abort "Failed to load config file (.pbsimple.yaml)"
    end

    File.open([@dir, ".indexes.rbm"].join("/")) do |f|
      @indexes = Marshal.load(f)
    end

    # Port from pbsimply-pandoc
    @pandoc_default_options = ["-t", "html5", "-s"]
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
    @pandoc_default_options.push (@config["template"] || "./template.html")

    if @config["pandoc_additional_options"]
      @pandoc_default_options.concat @config["pandoc_additional_options"]
    end
    # End of Ports

    # Get infomation
    @index = {}

    if @config["alt_frontmatter"]
      @index.merge! @config["alt_frontmatter"]
    end

    if File.file?([@dir, ".accs.yaml"].join("/"))
      @index.merge! YAML.load(File.read([@dir, ".accs.yaml"].join("/")))
    end


    # Pseudo instance variables
    @pandoc_options = @pandoc_default_options.clone
    @index["title"] ||= (@config["accs_index_title"] || "Index")
    @index["date"] ||= Time.now.strftime("%Y-%m-%d %H:%M:%S")
    @index["pagetype"] = "accs_index"

    doc = ERB.new(erbtemplate, nil, "%<>").result(binding)
    File.open([@dir, ".index.md"].join("/"), "w") do |f|
      f.write doc
    end

    IO.popen((["pandoc"] + @pandoc_options + [ [@dir, ".index.md"].join("/") ] )) do |io|
      doc = io.read
    end

    if @config["post_eruby"]
      doc = ERB.new(doc, nil, "%<>").result(binding)
    end

    File.open(([@config["outdir"], @dir, "index.html"].join("/")), "w") do |f|
      f.write(doc)
    end
  end
end

pbaccs.letsaccs

#pbaccs.methods
