#!/bin/env ruby

# Module for BLESSING feature.
module PBSimply::Prayer
  def bless frontmatter
    if @config["bless_style"] == "cmd"
      bless_cmd frontmatter
    else
      bless_ruby frontmatter
    end
  end
  
  def bless_ruby(frontmatter)
    # BLESSING (Always)
    if PureBuilder.const_defined?(:BLESS) && Proc === PureBuilder::BLESS
      begin
        PureBuilder::BLESS.(frontmatter, self)
      rescue
        STDERR.puts "*** BLESSING PROC ERROR ***"
        raise
      end
    end

    # BLESSING (ACCS)
    if @accs && PureBuilder::ACCS.const_defined?(:BLESS) && Proc === PureBuilder::ACCS::BLESS
      begin
        PureBuilder::ACCS::BLESS.(frontmatter, self)
      rescue
        STDERR.puts "*** ACCS BLESSING PROC ERROR ***"
        raise
      end
    end

    # ACCS DEFINITIONS
    if @accs
      if Proc === PureBuilder::ACCS::DEFINITIONS[:next]
        i = PureBuilder::ACCS::DEFINITIONS[:next].call(frontmatter, self)
        frontmatter["next_article"] = i if i
      end
      if Proc === PureBuilder::ACCS::DEFINITIONS[:prev]
        i = PureBuilder::ACCS::DEFINITIONS[:prev].call(frontmatter, self)
        frontmatter["prev_article"] = i if i
      end
    end

    autobless(frontmatter)
  end

  def bless_cmd(frontmatter)
    File.open(@workfile_frontmatter, "w") {|f| f.write JSON_LIB.dump(frontmatter) }
    # BLESSING (Always)
    if @config["bless_cmd"]
      (Array === @config["bless_cmd"] ? system(*@config["bless_cmd"]) : system(@config["bless_cmd"]) ) or abort "*** BLESS COMMAND RETURNS NON-ZERO STATUS"
    end
    # BLESSING (ACCS)
    if @config["bless_accscmd"]
      (Array === @config["bless_accscmd"] ? system({"pbsimply_workdir" => @workdir, "pbsimply_frontmatter" => @workfile_frontmatter, "pbsimply_indexes" => @db.path}, *@config["bless_accscmd"]) : system({"pbsimply_workdir" => @workdir, "pbsimply_frontmatter" => @workfile_frontmatter, "pbsimply_indexes" => @db.path}, @config["bless_accscmd"]) ) or abort "*** BLESS COMMAND RETURNS NON-ZERO STATUS"
    end
    mod_frontmatter = JSON.load(File.read(@workfile_frontmatter))
    frontmatter.replace(mod_frontmatter)

    autobless(frontmatter)
  end

  # Blessing automatic method with configuration.
  def autobless(frontmatter)
    catch(:accs_rel) do
      # find Next/Prev page on accs
      if @accs && @config["blessmethod_accs_rel"]
        # Preparing. Run at once.
        if !@article_order
          @rev_article_order_index = {}

          case @config["blessmethod_accs_rel"]
          when "numbering"
            @article_order = @indexes.to_a.sort_by {|i| i[1]["_filename"].to_i }
          when "date"
            begin
              @article_order = @indexes.to_a.sort_by {|i| i[1]["date"]}
            rescue
              abort "*** Automatic Blessing Method Error: Maybe some article have no date."
            end
          when "timestamp"
            begin
              @article_order = @indexes.to_a.sort_by {|i| i[1]["timestamp"]}
            rescue
              abort "*** Automatic Blessing Method Error: Maybe some article have no timetsamp."
            end
          when "lexical"
            @article_order = @indexes.to_a.sort_by {|i| i[1]["_filename"]}
          end
          @article_order.each_with_index {|x,i| @rev_article_order_index[x[0]] = i }
        end

        throw(:accs_rel) unless index = @rev_article_order_index[frontmatter["_filename"]]
        if @article_order[index + 1]
          frontmatter["next_article"] = {"url" => @article_order[index + 1][1]["page_url"],
                                         "title" => @article_order[index + 1][1]["title"]}
        end
        if index > 0
          frontmatter["prev_article"] = {"url" => @article_order[index - 1][1]["page_url"],
                                         "title" => @article_order[index - 1][1]["title"]}
        end
      end
    end
  end
end