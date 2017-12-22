#!/usr/bin/ruby
# -*- mode: ruby; coding: UTF-8 -*-

require 'webrick'
require 'yaml'

File.open(".pbsimply.yaml") do |f|
  @config = YAML.load(f)
end

srv = WEBrick::HTTPServer.new({ :DocumentRoot => @config["outdir"],
                                :BindAddress => '127.0.0.1',
                                :Port => 20080})
trap("INT"){ srv.shutdown }
srv.start
