#!/usr/bin/ruby

class PBSimply
  module Processor
    # RedCarpet Processor
    class PbsRedCarpet < PBSimply
      def initialize(config)
        require 'redcarpet'
        super
      end

      def setup_config(dir)
        super
        @rc_extension = @config["redcarpet_extensions"] || {}
      end

      def print_fileproc_msg(filename)
        STDERR.puts "#{filename} generate with Redcarpet Markdown"
      end

      def process_document(dir, filename, frontmatter, orig_filepath, ext, procdoc)
        # Getting HTML string.
        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, **@rc_extension)
        article_body = markdown.render(File.read procdoc)

        # Process with eRuby temaplte.
        erb_template = ERB.new(File.read(@config["template"]), trim_mode: '%<>')
        doc = erb_template.result(binding)

        doc
      end
    end

    # Kramdown Processor
    class PbsKramdown < PBSimply
      def initialize(config)
        require 'kramdown'
        super
      end

      def print_fileproc_msg(filename)
        STDERR.puts "#{filename} generate with Kramdown"
      end

      def process_document(dir, filename, frontmatter, orig_filepath, ext, procdoc)
        # Set feature options
        features = @config["kramdown_features"] || {}

        # Getting HTML string.
        markdown = Kramdown::Document.new(File.read(procdoc), **features)
        article_body = markdown.to_html

        # Process with eRuby temaplte.
        erb_template = ERB.new(File.read(@config["template"]), trim_mode: '%<>')
        doc = erb_template.result(binding)

        doc
      end
    end

    # CommonMark Processor
    class PbsCommonMark < PBSimply
      def initialize(config)
        require 'commonmarker'
        super
      end

      def print_fileproc_msg(filename)
        STDERR.puts "#{filename} generate with CommonMarker (cmark-gfm)"
      end

      def process_document(dir, filename, frontmatter, orig_filepath, ext, procdoc)
        # Getting HTML string.
        article_body = CommonMarker.render_doc(File.read(procdoc), :DEFAULT, [:table, :strikethrough]).to_html

        # Process with eRuby temaplte.
        erb_template = ERB.new(File.read(@config["template"]), trim_mode: '%<>')
        doc = erb_template.result(binding)

        doc
      end
    end
  end
end