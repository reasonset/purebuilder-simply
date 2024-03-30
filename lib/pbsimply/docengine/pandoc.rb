#!/usr/bin/ruby

###############################################
#           DOCUMENT PROCESSORS               #
###############################################

class PBSimply
  module Processor

    # Pandoc processor
    class Pandoc < PBSimply
      def initialize(config)
        @pandoc_default_file = {}

        # -d
        @pandoc_default_file = {
          "to" => "html5",
          "standalone" => true
        }
        super
      end

      def setup_config(dir)
        super
        @pandoc_default_file["template"] = @config["template"]

        if @config["css"]
          if @config["css"].kind_of?(String)
            @pandoc_default_file["css"] = [@config["css"]]
          elsif @config["css"].kind_of?(Array)
            @pandoc_default_file["css"] = @config["css"]
          else
            abort "css in Config should be a String or an Array."
          end
        end

        if @config["toc"]
          @pandoc_default_file["toc"] = true
        end

        if Hash === @config["pandoc_additional_options"]
          @pandoc_default_file.merge! @config["pandoc_additional_options"]
        end

      end

      # Invoke pandoc, parse and format and write out.
      def print_fileproc_msg(filename)
        STDERR.puts "#{filename} is going Pandoc."
      end

      def process_document(dir, filename, frontmatter, orig_filepath, ext, procdoc)
        doc = nil

        File.open(@workfile_pandoc_defaultfiles, "w") {|f| YAML.dump(@pandoc_default_file, f)}
        File.open(@workfile_frontmatter, "w") {|f| YAML.dump(frontmatter, f)}

        # Go Pandoc
        pandoc_cmdline = [(@config["pandoc_command"] || "pandoc")]
        pandoc_cmdline += ["-d", @workfile_pandoc_defaultfiles, "--metadata-file", @workfile_frontmatter, "-M", "title:#{frontmatter["title"]}", "-w", "html5"]
        pandoc_cmdline += ["-f", frontmatter["input_format"]] if frontmatter["input_format"]
        pandoc_cmdline += [ procdoc ]
        pp pandoc_cmdline if ENV["DEBUG"] == "yes"
        IO.popen((pandoc_cmdline)) do |io|
          doc = io.read
        end

        # Abort if pandoc returns non-zero status
        if $?.exitstatus != 0
          abort "Pandoc returns exit code #{$?.exitstatus}"
        end

        doc
      end

      def target_file_extensions
        [".md", ".rst"]
      end
    end
  end
end