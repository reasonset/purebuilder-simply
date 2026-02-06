#!/bin/env ruby
require 'time'
require 'erb'

module PBSimply::ERuby
  include ::ERB::Util

  class WrapErubi
    def initialize
      require 'erubi'
    end

    def load_doc str
      @processor = ::Erubi::Engine.new(str)
      self
    end

    def generate bounded
      eval(@processor.src, bounded)
    end
  end

  class WrapErubis
    def initialize
      require 'erubis'
    end

    def load_doc str
      @processor = ::Erubis::Eruby.new(str)
      self
    end

    def generate bounded
      @processor.result(bounded)
    end
  end

  class WrapErb
    def initialize config
      @config = config
    end

    def load_doc str
      @processor = ::ERB.new(str, trim_mode: (@config["erb_trm_mode"] || "%<>"))
      self
    end

    def generate bounded
      @processor.result(bounded)
    end
  end

  def erblib
    return @eruby_lib if @eruby_lib
    case @config["eruby_lib"]
    when "erubis"
      @eruby_lib = WrapErubis.new
    when "erubi"
      @eruby_lib = WrapErubi.new
    else
      @eruby_lib = WrapErb.new @config
    end

    @eruby_lib
  end

  def file_and_render fp, bounded
    erblib.load_doc(File.read(fp)).generate(bounded)
  end

  def str_and_render str, bounded
    erblib.load_doc(str).generate(bounded)
  end

  private

  def parse_time
    if (Numeric === time_elem && time_elem > 1000000000000)
      # JavaScript milliseconds
      Time.at(time_elem / 1000)
    elsif Numeric === time_elem
      # Unix
      Time.at(time_elem)
    elsif String === time_elem
      # Generic String
      Time.parse(time_elem)
    elsif Array === time_elem
      # #local arguments array
      Time.local(*time_elem)
    else
      Time.now
    end
  end

  def iso8601 time_elem
    parse_time(time_elem).iso8601
  end

  def httpdate time_elem
    parse_time(time_elem).httpdate
  end

  def rfc822 time_elem
    parse_time(time_elem).rfc822
  end

  alias rfc2822 rfc822

  def xmldate time_elem
    parse_time(time_elem).xmlschema
  end
end