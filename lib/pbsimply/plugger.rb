# Document tweaking module.
# Provides deprected Pre-plugins and Post-plugins.
module PBSimply::Plugger
  POST_PROCESSORS = {
    ".rb" => "ruby",
    ".pl" => "perl",
    ".py" => "python",
    ".lua" => "lua",
    ".bash" => "bash",
    ".zsh" => "zsh",
    ".php" => "php",
    ".sed" => ["sed", ->(script, target) { ["-f", script, target] } ]
  }

  # Deprecated filter command feature.
  #
  # Pre plugins invoke each command on .pre_generate directory as filter command before process document.
  # Porcessing document (same content as source document) path given as first argument.
  def pre_plugins(procdoc, frontmatter)
    if File.directory?(".pre_generate")
      $stderr.puts("Processing with pre plugins")
      script_file = File.join(".pre_generate", script_file)
      Dir.entries(".pre_generate").sort.each do |script_file|
        next if script_file =~ /^\./
        $stderr.puts "Running script: #{File.basename script_file}"
        pre_script_result = nil
        script_cmdline = case
        when File.executable?(script_file)
          [script_file, procdoc]
        when POST_PROCESSORS[File.extname(script_file)]
          [POST_PROCESSORS[File.extname(script_file)], script_file, procdoc]
        else
          ["perl", script_file, procdoc]
        end
        IO.popen({"pbsimply_doc_frontmatter" => YAML.dump(frontmatter)}, script_cmdline) do |io|
          pre_script_result = io.read
        end
        File.open(procdoc, "w") {|f| f.write pre_script_result}
      end
    end
  end

  # Post plugins invoke each command on .post_generate directory as filter command after processed.
  # Generated document (typically HTML) path given as first argument.
  def post_plugins(frontmatter=nil)
    if File.directory?(".post_generate")

      $stderr.puts("Processing with post plugins")

      @this_time_processed.each do |v|
        $stderr.puts "Processing #{v[:dest]} (from #{v[:source]})"
        procdoc = v[:dest]
        frontmatter ||= @indexes[File.basename v[:source]]
        File.open(@workfile_frontmatter, "w") {|f| f.write PBSimply::JSON_LIB.dump(frontmatter)}
        Dir.entries(".post_generate").sort.each do |script_file|
          next if script_file =~ /^\./
          $stderr.puts "Running script: #{script_file}"
          script_file = File.join(".post_generate", script_file)
          post_script_result = nil
          script_cmdline = case
          when File.executable?(script_file)
            [script_file, procdoc]
          when POST_PROCESSORS[File.extname(script_file)]
            [POST_PROCESSORS[File.extname(script_file)], script_file, procdoc]
          else
            ["perl", script_file, procdoc]
          end
          IO.popen({"pbsimply_workdir" => @workdir,"pbsimply_frontmatter" => @workfile_frontmatter, "pbsimply_indexes" => @db.path}, script_cmdline) do |io|
            post_script_result = io.read
          end

          File.open(procdoc, "w") {|f| f.write post_script_result}
        end
      end
    end
  end
end
