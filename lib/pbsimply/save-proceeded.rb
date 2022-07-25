require 'pbsimply'

class PBSimply
  class SaveProceeded

    def self.sp_class(config)
      # Enable option.
      return nil unless Hash === config["save_proceeded_document"]

      return case config["save_proceeded_document"]["database"]
      when "qdbm"
        QDBM.new(config)
      when "dbm"
        PbSP_DBM.new(config)
      when 'yaml'
        YAML.new(config)
      when "json"
        JSON.new(config)
      when "pbss"
        PbSS.new(config)
      else
        Marshal.new(config)
      end
    end

    def initialize(config)
      @config = config
      @outdir = config["save_proceeded_document"]["outdir"] || './.save_proceeded'
      @target_pathes = []
      if Array === @config["save_proceeded_document"]["target_path"]
        @config["save_proceeded_document"]["target_path"].each do |i|
          @target_pathes.push(Regexp.new(i))
        end
      end
    end

    def auto(tfp, frontmatter, procdoc)
      if !@target_pathes.empty? && !@target_pathes.any? {|i| i === frontmatter["source_path"].sub(/^\.\//, "") }
        return nil
      end
      STDERR.puts "Save proceeded document."
      doc = nil
      case @config["save_proceeded_document"]["content"]
      when "meta"
        doc = nil
      when "pandoc_plain"
        unless File.exist?(".pbsimply_pandoc_plain_template.txt")
          File.open(".pbsimply_pandoc_plain_template.txt", "w") do |f|
            f.puts <<'EOF'
$if(titleblock)$
$titleblock$
$endif$

$body$
EOF
          end
        end
        IO.popen(["pandoc", "-t", "plain", "--template", "./.pbsimply_pandoc_plain_template.txt", procdoc]) {|io| doc = io.read}
      else
        doc = File.read(procdoc)
      end

      data = frontmatter.clone

      data["_article_data"] = doc
      save(tfp, data)
    end

    def save(tfp, data)
      File.open(File.join(@outdir, Digest::SHA1.hexdigest(tfp)) + getext, "w") {|f| f.write dump(data) }
    end

    def remove(tfp)
      if File.exist?(File.join(@outdir, Digest::SHA1.hexdigest(tfp)) + getext)
        File.delete(File.join(@outdir, Digest::SHA1.hexdigest(tfp)) + getext)
      end
    end

    class PbSP_DBM < SaveProceeded
      def initialize(config)
        super
        require 'yaml/dbm'
      end

      def save(tfp, data)
        ::YAML::DBM.new(File.join(@outdir, "saved_index.dbm"), 0644, ::DBM::WRITER | ::DBM::WRCREAT) do |dbm|
          dbm[tfp] = Marshal.dump(data)
        end
      end

      def remove(tfp)
        ::YAML::DBM.new(File.join(@outdir, "saved_index.dbm"), 0644, ::DBM::WRITER | ::DBM::WRCREAT) do |dbm|
          dbm.delete(tfp) if dbm[tfp]
        end
      end
    end

    class QDBM < SaveProceeded
      def save(tfp, data)
        Depot.new(File.join(@outdir, "saved_index.qdbm"), Depot::OWRITER | Depot::OCREAT) do |dbm|
          dbm[tfp] = Marshal.dump(data)
        end
      end

      def remove(tfp)
        Depot.new(File.join(@outdir, "saved_index.qdbm"), Depot::OWRITER | Depot::OCREAT) do |dbm|
          dbm.delete tfp if dbm[tfp]
        end
      end
    end

    class JSON < SaveProceeded
      def dump(data)
        ::PBSimply::JSON_LIB.dump(data)
      end

      def getext
        ".json"
      end
    end

    class Marshal < SaveProceeded
      def dump(data)
        ::Marshal.dump(data)
      end

      def getext
        ".rbm"
      end
    end

    class YAML < SaveProceeded
      def dump(data)
        ::YAML.dump(data)
      end

      def getext
        ".yaml"
      end
    end

    class PbSS < SaveProceeded
      def save(tfp, data)
        docbody = data.delete("_article_data")
        if docbody =~ /\A---$/
          docbody.sub!(/\A---.*?^---$/m, "")
        end
        docbody = data["title"] + "\n\n" + docbody
        Dir.mkdir(File.join(@outdir, "metadata")) unless File.exist? File.join(@outdir, "metadata")
        File.open(File.join(@outdir, "metadata", Digest::SHA1.hexdigest(tfp)) + ".yaml", "w") {|f| ::YAML.dump(data, f) }
        Dir.mkdir(File.join(@outdir, "body")) unless File.exist? File.join(@outdir, "body")
        File.open(File.join(@outdir, "body", Digest::SHA1.hexdigest(tfp)), "w") {|f| f.write docbody }
      end

      def remove(tfp)
        if File.exist?(File.join(@outdir, "metadata", Digest::SHA1.hexdigest(tfp)) + ".yaml")
          File.delete(File.join(@outdir, "metadata", Digest::SHA1.hexdigest(tfp)) + ".yaml")
        end
        if File.exist?(File.join(@outdir, "body", Digest::SHA1.hexdigest(tfp)))
          File.delete(File.join(@outdir, "body", Digest::SHA1.hexdigest(tfp)))
        end  
      end

    end
  end
end