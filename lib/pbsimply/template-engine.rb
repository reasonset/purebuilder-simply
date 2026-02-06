#!/bin/env ruby

module PBSimply::TemplateEngine
  class TplEngineLiquid
    def initialize template
      require 'liquid'
      @template = template
    end

    def generate frontmatter, article_body
      Liquid::Template.parse(@template).render(
        "frontmatter" => frontmatter,
        "article_body" => body
      )
    end
  end

  class TplEngineMustache
    def initialize template
      require 'mustache'
      @template = template
    end

    def generate frontmatter, article_body
      Mustache.render(@template, {
        frontmatter: frontmatter,
        article_body: article_body
      })
    end
  end

  def expand_template binding
    $stderr.puts @config["template_format"]
    case @config["template_format"]
    when "liquid"
      tpl = TplEngineLiquid.new(File.read(@config["template"]))
      tpl.generate(binding.local_variable_get(:frontmatter), binding.local_variable_get(:article_body))
    when "mustache"
      $stderr.puts "mustache"
      tpl = TplEngineMustache.new(File.read(@config["template"]))
      tpl.generate(binding.local_variable_get(:frontmatter), binding.local_variable_get(:article_body))
    else
      file_and_render(@config["template"], binding)
    end
  end
end