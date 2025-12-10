require 'pbsimply/frontmatter'

class PBSimply
  class Document
    include Frontmatter

    def initialize(config, dir, filename, base_frontmatter, now)
      @config = config
      @dir = dir
      @filename = filename
      @ext = File.extname filename
      @orig_filepath = File.join(dir, filename)
      @now = now
      frontmatter, @pos = read_frontmatter(dir, filename)
      @frontmatter = base_frontmatter.merge frontmatter
      @modified = true
      @proc_doc_path = nil
    end

    attr_reader :frontmatter, :filename, :pos, :ext, :proc_doc_path, :orig_filepath
    attr_accessor :orig_frontmatter, :now

    def add_meta(additional_meta)
      frontmatter.merge!(additional_meta)
    end

    def read_document(workdir: "")
      File.open(File.join(@dir, @filename)) do |f|
        f.seek(@pos)
        doc_content = f.read
        if @config["unicode_normalize"] && !@frontmatter["skip_normalize"]
          doc_content.unicode_normalize!(@config["unicode_normalize"].to_sym)
        end
        File.open(File.join(workdir, "current_document#{@ext}"), "w") do |fo|
          fo.write doc_content
        end
      end

      @proc_doc_path = File.join(workdir, "current_document#{@ext}")
    end

    def draft?
      frontmatter["draft"]
    end

    def to_a
      [@dir, @filename, @frontmatter]
    end

    # Check is the article modified? (or force update?)
    def modified?
      index = @orig_frontmatter ||= {}

      case @config["detect_modification"]
      when "changes"
        # Use "changes"
        @modified = false if @frontmatter["changes"] == index["changes"]
      when "mtimesize"
        # Use mtime and file size.
        @modified = false if @frontmatter["_mtime"] <= (index["_last_proced"] || 0) && @frontmatter["_size"] == index["_size"]
      else
        # Default method, use mtime.
        @modified = false if @frontmatter["_mtime"] <= (index["_last_proced"] || 0)
      end

      if @modified
        $stderr.puts "#{@filename} last modified at #{@frontmatter["_mtime"]}, last processed at #{index["_last_proced"] || 0}"
      else
        $stderr.puts "#{@filename} is not modified."
      end

      set_timestamp

      if @frontmatter["skip_update"]
        # Document specific skip update
        @modified = false
      elsif index["_modified"]
        @modified = true
      else
        @modified
      end
    end

    def mark_meta_modified
      # Frontmatter used as a reference for metadata update detection.
      # Keys that are always updated during processing should be removed.
      ex_keys = ["_last_proced", "last_update"] + (@config["compr_ex_keys"] || [])
      @orig_frontmatter ||= {}
      compr_frontmatter = @orig_frontmatter.except(*ex_keys) # Hash#except from Ruby 2.0

      if compr_frontmatter == frontmatter
        @modified = false
      else
        @frontmatter["_modified"] = true
        @frontmatter.merge!(@orig_frontmatter.slice(*ex_keys))
      end
    end

    def effective_forntmatter
      @modified ? @frontmatter : @orig_frontmatter
    end

    private

    def set_timestamp
      @frontmatter["_last_proced"] = @now.to_i
      @frontmatter["last_update"] = @now.strftime("%Y-%m-%d %H:%M:%S")
    end
  end
end