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
    
    if File.exist?(File.join(@dir, ".accsindex.erb"))
      erbtemplate = File.read(File.join(@dir, ".accsindex.erb"))
    elsif File.exist?(".accsindex.erb")
      erbtemplate = File.read(".accsindex.erb")
    else
      abort "No .accesindex.erb"
    end

    begin
      File.open(".pbsimply.yaml") do |f|
        @config = YAML.load(f)
      end
    rescue
      abort "Failed to load config file (.pbsimply.yaml)"
    end

    fp = [".accs_index.rbm", ".indexes.rbm"].map {|i| File.join(@dir, i)}.select {|i| File.exist? i }.first or abort "Missing Index File."

    File.open(fp) do |f|
      @indexes = Marshal.load(f)
    end

    # Get infomation
    @index = {}

    if File.file?([@dir, ".accs.yaml"].join("/"))
      @index.merge! YAML.load(File.read([@dir, ".accs.yaml"].join("/")))
    end

    @index["title"] ||= (@config["accs_index_title"] || "Index")
    @index["date"] ||= Time.now.strftime("%Y-%m-%d")
    @index["pagetype"] = "accs_index"

    doc = ERB.new(erbtemplate, nil, "%<>").result(binding)
    File.open([@dir, ".index.md"].join("/"), "w") do |f|
      f.write doc
    end

    IO.popen(["pbsimply-pandoc.rb", "-A", File.join(@dir, ".index.md")])
  end
end

pbaccs.letsaccs
