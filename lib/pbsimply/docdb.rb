#!/usr/bin/ruby

class PBSimply
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
    end

    # Use JSON with bundled library
    class JSON < DocDB
      def initialize(dir)
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
        @store_class = ::YAML
        @ext = "yaml"
      end
    end
  end
end