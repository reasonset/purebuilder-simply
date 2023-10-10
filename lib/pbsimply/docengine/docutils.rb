#!/usr/bin/ruby

class PBSimply
  module Processor
    # Docutils processor (rst2html5 command)
    class Docutils < PBSimply
      def initialize(config)
        @docutils_cli_options = []
        super
      end

      def setup_config(dir)
        super
        @docutils_cli_options.push("--template=#{@config["template"]}") if @config["template"]

        if @config["css"]
          if @config["css"].kind_of?(String)
            @docutils_cli_options.push("--stylesheet=#{@config["css"]}")
          elsif @config["css"].kind_of?(Array)
            @docutils_cli_options.push("--stylesheet=#{@config["css"].join(",")}")
          else
            abort "css in Config should be a String or an Array."
          end
        end

        if Array === @config["docutils_options"]
          @docutils_cli_options.concat! @config["docutils_options"]
        end
      end

      # Invoke pandoc, parse and format and write out.
      def print_fileproc_msg(filename)
        STDERR.puts "#{filename} is going Docutils."
      end

      def process_document(dir, filename, frontmatter, orig_filepath, ext, procdoc)
        doc = nil

        # Go Docutils
        cmdline = ["rst2html5"]
        cmdline += @docutils_cli_options
        cmdline += [ procdoc ]
        IO.popen((cmdline)) do |io|
          doc = io.read
        end

        # Abort if pandoc returns non-zero status
        if $?.exitstatus != 0
          abort "Docutils (rst2html5) returns exit code #{$?.exitstatus}"
        end

        doc
      end

      def target_file_extensions
        [".rst"]
      end
    end
  end
end