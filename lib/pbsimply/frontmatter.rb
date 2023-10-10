#!/usr/bin/ruby
require 'erb'
require 'yaml'

module PBSimply::Frontmatter
  # Read Frontmatter from the document.
  # This method returns frontmatter, pos.
  # pos means position at end of Frontmatter on the file.
  def read_frontmatter(dir, filename)
    frontmatter = nil
    pos = nil

    source_path = File.join(dir, filename)

    if File.exist? File.join(dir, ".meta." + filename)
      # Load standalone metadata YAML.
      frontmatter = Psych.unsafe_load(File.read(File.join(dir, (".meta." + filename))))
      pos = 0
    else

      case File.extname filename
      when ".md"

        # Load Markdown's YAML frontmatter.
        File.open(source_path) do |f|
          l = f.gets
          next unless l && l.chomp == "---"

          lines = []

          while l = f.gets
            break if l.nil?

            break if  l.chomp == "---"
            lines.push l
          end

          next if f.eof?

          begin
            frontmatter = Psych.unsafe_load(lines.join)
          rescue => e
            STDERR.puts "!CRITICAL: Cannot parse frontmatter."
            raise e
          end

          pos = f.pos
        end

      when ".rst"
        # ReSTRUCTURED Text

        File.open(source_path) do |f|
          l = f.gets
          if l =~ /:([A-Za-z_-]+): (.*)/ #docinfo
            frontmatter = { $1 => [$2.chomp] }
            last_key = $1

            # Read docinfo
            while(l = f.gets)
              break if l =~ /^\s*$/ # End of docinfo
              if l =~ /^\s+/ # Continuous line
                docinfo_lines.last.push($'.chomp)
              elsif l =~ /:([A-Za-z_-]+): (.*)/
                frontmatter[$1] = [$2.chomp]
                last_key = $1
              end
            end

            # Treat docinfo lines
            frontmatter.each do |k,v|
              v = v.join(" ")
              #if((k == "author" || k == "authors") && v.include?(";")) # Multiple authors.
              if(v.include?(";")) # Multiple element.
                v = v.split(/\s*;\s*/)

              elsif k == "date" # Date?
                # Datetime?
                if v =~ /[0-2][0-9]:[0-6][0-9]/
                  v = Time.parse(v)
                else
                  v = Date.parse(v)
                end
              elsif v == "yes" || v == "true"
                v = true
              else # Simple String.
                nil # keep v
              end

              frontmatter[k] = v
            end

          elsif l && l.chomp == ".." #YAML
            # Load ReST YAML that document begins comment and block is yaml.
            lines = []

            while(l = f.gets)
              if(l !~ /^\s*$/ .. l =~ /^\s*$/)
                if l=~ /^\s*$/
                  break
                else
                  lines.push l
                end
              end
            end
            next if f.eof?


            # Rescue for failed to read YAML.
            begin
              frontmatter = Psych.unsafe_load(lines.map {|i| i.sub(/^\s*/, "") }.join)
            rescue
              STDERR.puts "Error in parsing ReST YAML frontmatter (#{$!})"
              next
            end
          else
            next
          end

          pos = f.pos

        end
      end
    end

    abort "This document has no frontmatter" unless frontmatter
    abort "This document has no title." unless frontmatter["title"]

    outext = frontmatter["force_ext"] || ".html"
    outpath = case
    when @outfile
      @outfile
    when @accs_processing
      File.join(@config["outdir"], @dir, "index") + outext
    else
      File.join(@config["outdir"], @dir, File.basename(filename, ".*")) + outext
    end

    absolute_current = File.absolute_path Dir.pwd
    absolute_docdir = File.absolute_path dir
    absolute_docpath = File.absolute_path source_path
    pwd_length = absolute_current.length

    ### Additional meta values. ###
    frontmatter["source_directory"] = dir # Source Directory
    frontmatter["source_filename"] = filename # Source Filename
    frontmatter["source_path"] = source_path # Source Path
    frontmatter["dest_path"] = outpath
    frontmatter["normalized_docdir"] = absolute_docdir[pwd_length..]
    frontmatter["normalized_docpath"] = absolute_docpath[pwd_length..]
    # URL in site.
    this_url = (source_path).sub(/^[\.\/]*/) { @config["self_url_prefix"] || "/" }.sub(/\.[a-zA-Z0-9]+$/, ".html")
    frontmatter["page_url"] = this_url
    # URL in site with URI encode.
    frontmatter["page_url_encoded"] = ERB::Util.url_encode(this_url)
    frontmatter["page_url_encoded_external"] = ERB::Util.url_encode((source_path).sub(/^[\.\/]*/) { @config["self_url_external_prefix"] || "/" }.sub(/\.[a-zA-Z0-9]+$/, ".html"))
    frontmatter["page_html_escaped"] = ERB::Util.html_escape(this_url)
    frontmatter["page_html_escaped_external"] = ERB::Util.html_escape((source_path).sub(/^[\.\/]*/) { @config["self_url_external_prefix"] || "/" }.sub(/\.[a-zA-Z0-9]+$/, ".html"))
    # Title with URL Encoded.
    frontmatter["title_encoded"] = ERB::Util.url_encode(frontmatter["title"])
    frontmatter["title_html_escaped"] = ERB::Util.html_escape(frontmatter["title"])
    fts = frontmatter["timestamp"]
    fts = fts.to_datetime if Time === fts
    if DateTime === fts
      frontmatter["timestamp_xmlschema"] = fts.xmlschema
      frontmatter["timestamp_jplocal"] = fts.strftime('%Y年%m月%d日 %H時%M分%S秒')
      frontmatter["timestamp_rubytimestr"] = fts.strftime('%a %b %d %H:%M:%S %Z %Y')
      frontmatter["timestamp_str"] = fts.strftime("%Y-%m-%d %H:%M:%S %Z")
    elsif Date === fts
      frontmatter["timestamp_xmlschema"] = fts.xmlschema
      frontmatter["timestamp_jplocal"] = fts.strftime('%Y年%m月%d日')
      frontmatter["timestamp_rubytimestr"] = fts.strftime('%a %b %d')
      frontmatter["timestamp_str"] = fts.strftime("%Y-%m-%d")
    elsif Date === frontmatter["Date"]
      fts = frontmatter["Date"]
      frontmatter["timestamp_xmlschema"] = fts.xmlschema
      frontmatter["timestamp_jplocal"] = fts.strftime('%Y年%m月%d日')
      frontmatter["timestamp_rubytimestr"] = fts.strftime('%a %b %d')
      frontmatter["timestamp_str"] = fts.strftime("%Y-%m-%d")
    end

    fsize = FileTest.size(source_path)
    mtime = File.mtime(source_path).to_i

    frontmatter["_filename"] ||= filename
    frontmatter["pagetype"] ||= "post"

    frontmatter["_size"] = fsize
    frontmatter["_mtime"] = mtime
    frontmatter["_last_proced"] = @now.to_i

    if File.extname(filename) == ".md"
      frontmatter["_docformat"] = "Markdown"
    elsif File.extname(filename) == ".rst" || File.extname(filename) == ".rest"
      frontmatter["_docformat"] = "ReST"
    elsif File.extname(filename) == ".rdoc"
      frontmatter["_docformat"] = "RDoc"
    end

    frontmatter["date"] ||= @now.strftime("%Y-%m-%d %H:%M:%S")

    return frontmatter, pos
  end
end