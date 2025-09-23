#!/bin/env ruby

# ACCS namespace.
module PBSimply::ACCS
  DEFINITIONS = {}

  # Built-in Accs index eRuby string.
  INDEX = <<'EOF'
<%= YAML.dump(
  {
    "title" => @index["title"],
    "date" => @index["date"],
    "author" => @index["author"]
  }
) %>
---

<%
articles = Hash.new {|h,k| h[k] = Array.new }

if @config["accs_across_category"]
  @indexes.each {|filename, index| articles["default"].push index }
else
  @indexes.each {|filename, index| articles[(index["category"] || "default")].push index }
end

%>

% articles.keys.sort.each do |catname|
% cat = articles[catname]

% unless articles.length == 1
# <%= catname %>
% end

<%
  sort_method = case @config["accs_sort_by"]
  when "title"
    lambda {|i| [i["title"].to_s, i["date"]] }
  when "name"
    lambda {|i| [i["_filename"].to_s, i["title"].to_s, i["date"]] }
  when "serial"
    lambda {|i| [i["serial"].to_s, i["date"], i["_filename"].to_s] }
  else
    lambda {|i| [i["date"], i["title"].to_s, i["_last_update"].to_i] }
  end

  list = if @config["accs_order"] == "desc"
    cat.sort_by(&sort_method).reverse
  else
    cat.sort_by(&sort_method)
  end

  list.each do |i|
%>* [<%= i["title"] %>](<%= i["page_url"] %>)
<% end %>

% end
EOF

  # letsaccs
  #
  # This method called on the assumption that processed all documents and run as directory mode.
  def process_accs
    $stderr.puts "Processing ACCS index..."
    if File.exist?(File.join(@dir, ".accsindex.erb"))
      erbtemplate = File.read(File.join(@dir, ".accsindex.erb"))
    elsif File.exist?(".accsindex.erb")
      erbtemplate = File.read(".accsindex.erb")
    else
      erbtemplate = INDEX
    end

    # Get infomation
    @accs_index = Psych.unsafe_load(File.read([@dir, ".accs.yaml"].join("/")))

    @accs_index["title"] ||= (@config["accs_index_title"] || "Index")
    @accs_index["date"] ||= Time.now.strftime("%Y-%m-%d")
    @accs_index["pagetype"] = "accs_index"

    @index = @frontmatter.merge @accs_index

    @hooks.accs.run({index: @index, indexes: @indexes})

    doc = ERB.new(erbtemplate, trim_mode: "%<>").result(binding)
    File.open(File.join(@dir, ".index.md"), "w") do |f|
      f.write doc
    end

    accsmode
    @dir = File.join(@dir, ".index.md")
    main
  end

  # Turn on ACCS processing mode.
  def accsmode
    @accs_processing = true
    @singlemode = true
    @skip_index = true
  end

  # letsaccs in single page.
  def single_accs filename, frontmatter
    unless @skip_index
      @indexes[filename] = frontmatter
      @db.dump(@indexes)
    end
    process_accs
  end
end
