require 'json'

class PBSimply
  class Utils
    def self.normalize_source_path path
      root = File.expand_path Dir.pwd
      path = File.expand_path path
      unless root == path[0, root.length]
        raise InvalidPathError.new("source path not match to document root.")
      end
      path[root.length..].sub(%r:^/:, "")
    end
  end

  class JsonlLogger
    def initialize enabled
      @logfile = nil
      if enabled
        unless File.exist? ".pbsimply_var"
          Dir.mkdir(".pbsimply_var")
        end
        @logfile = File.open(File.join(".pbsimply_var", "log.jsonl"), "a")
        @logfile.flock(File::LOCK_EX)
        @logfile.seek(0, IO::SEEK_END)
      end
    end

    def generate frontmatter
      return unless @logfile
      @logfile.puts JSON.generate({
        "action" => "generate",
        "filepath" => frontmatter["source_path"],
        "timestamp" => Time.now.to_i,
        "title" => frontmatter["title"],
        "url" => frontmatter["page_url"],
        "size" => frontmatter["_size"],
        "format" => frontmatter["_docformat"]
      })
    end

    def delete fp
      return unless @logfile
      @logfile.puts JSON.generate({
        "action" => "delete",
        "filepath" => Utils.normalize_source_path(fp),
        "timestamp" => Time.now.to_i
      })
    end
  end

  class TitleMapDB
    def initialize enabled
      @db = nil
      if enabled
        require 'dbm'
        unless File.exist? ".pbsimply_var"
          Dir.mkdir(".pbsimply_var")
        end
        @db = DBM.new(File.join(".pbsimply_var", "titlemap"))
        @key = "title"
        @key = "title_encoded" if enabled == "url_encoded"
        @key = "title_html_escaped" if enabled == "html_escaped"
      end
    end

    def []=(path, frontmatter)
      return unless @db
      now = Time.now.to_i
      val = @db[path]
      val = val ? JSON.load(val) : {}
      if val[frontmatter[@key]]
        val[frontmatter[@key]]["last_update"] = now
      else
        val[frontmatter[@key]] = {
          "since" => now,
          "last_update" => now
        }
      end

      @db[path] = val
    end
  end
end