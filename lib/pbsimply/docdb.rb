#!/usr/bin/ruby
require 'yaml'

class PBSimply
  class CustomYAML
    def self.dump(*arg)
      YAML.dump(*arg)
    end

    def self.load(*arg)
      Psych.unsafe_load(*arg)
    end
  end

  # Abstruct super class.
  class DocDB
    def dump(object)
      File.open(File.join(@dir, ".indexes.#{@ext}"), wmode) do |f|
        f.write @store_class.dump(object)
      end
    end

    def load
      File.open(File.join(@dir, ".indexes.#{@ext}"), rmode) do |f|
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

    def wmode
      "w"
    end

    def rmode
      "r"
    end

    # Use Ruby Marshal
    class Marshal < DocDB
      def initialize(dir)
        @dir = dir
        @store_class = ::Marshal
        @ext = "rbm"
      end

      def cmp_obj(frontmatter)
        frontmatter.dup
      end

      def wmode
        "wb"
      end

      def rmode
        "rb"
      end
    end

    # Use JSON with bundled library
    class JSON < DocDB
      def initialize(dir)
        require 'json'
        @dir = dir
        @store_class = ::JSON
        @ext = "json"
      end
    end

    # Use JSON with Oj gem
    class Oj < DocDB::JSON
      def initialize(dir)
        require 'oj'
        @dir = dir
        @ext = "json"
        @store_class = ::Oj
      end
    end

    # Use YAML
    class YAML < DocDB
      def initialize(dir)
        @dir = dir
        @store_class = CustomYAML
        @ext = "yaml"
      end
    end
  end
end