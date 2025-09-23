#!/bin/env ruby

class PBSimply
  module Processor
    # RDoc family Base
    class PbsRBase < PBSimply
      def initialize(config)
        require 'rdoc'
        require 'rdoc/markup/to_html'

        @rdoc_options = RDoc::Options.new
        @rdoc_markup = RDoc::Markup.new

        super
      end

      def process_document(dir, filename, frontmatter, orig_filepath, ext, procdoc)
        # Getting HTML string.
        rdoc = RDoc::Markup::ToHtml.new(@rdoc_options, @rdoc_markup)
        article_body = rdoc.convert(get_markup_document(procdoc))

        # Process with eRuby temaplte.
        erb_template = ERB.new(File.read(@config["template"]), trim_mode: '%<>')
        doc = erb_template.result(binding)

        doc
      end
    end

    # RDoc/Markdown processor
    class PbsRMakrdown < PbsRBase
      def initialize(config)
        require 'rdoc'
        require 'rdoc/markdown'
        super
      end

      def print_fileproc_msg(filename)
        $stderr.puts "#{filename} generate with RDoc/Markdown"
      end

      def get_markup_document procdoc
        RDoc::Markdown.parse(File.read procdoc)
      end
    end

    # RDoc processor
    class PbsRDoc < PbsRBase
      def print_fileproc_msg(filename)
        $stderr.puts "#{filename} generate with RDoc"
      end

      def get_markup_document procdoc
        File.read procdoc
      end

      def target_file_extensions
        [".rdoc"]
      end
    end
  end
end
