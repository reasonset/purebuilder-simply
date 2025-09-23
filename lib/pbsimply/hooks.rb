#!/bin/env ruby

# Hooks is new in PureBuilder Simply 2.2.
# Hooks object has instance variables for each timing.
#
class PBSimply::Hooks

  # Timing object class.
  class HooksHolder
    def initialize name
      @name = name
      @hooks = []
    end

    def <<(proc)
      @hooks << proc
    end

    def add(&proc)
      @hooks << proc
    end

    # Invoke command updating files
    def cmd(*cmdarg)
      proc = ->(arg) do
        system(*cmdarg)
      end
      self << proc
    end

    def run(arg)
      $stderr.puts "Hooks processing (#{@name})"
      @hooks.each_with_index do |proc, index|
        $stderr.puts "Hooks[#{index}]"
        begin
          proc.(arg)
        rescue
          $stderr.puts "*** HOOKS PROC ERROR ***"
          raise
        end
      end
    end
  end

  # Timing Object for pre, process
  class HooksHolderPre < HooksHolder
    # Invoke command as filter.
    def filter(*cmdarg)
      proc = ->(arg) do
        IO.popen(cmdarg, "w+") do |io|
          io.print File.read ENV["pbsimply_currentdoc"]
          io.close_write
          File.open(ENV["pbsimply_currentdoc"], "w") do |f|
            f.write io.read
          end
        end
      end
      self << proc
    end
  end

  def initialize(pbsimply, config)
    @pbsimply = pbsimply
    @config = config
    @hooks_loaded = false

    # Called first phase before generate. This hooks called before blessing.
    #
    # Argument: frontmatter, procdoc.
    # procdoc is processing source document path.
    @pre = HooksHolderPre.new "pre"

    # Called after document was generated.
    #
    # Argument: outpath, frontmatter, procdoc.
    # outpath is generated final document path. You can read output result.
    # procdoc is source document path before generate.
    @process = HooksHolder.new "process"

    # Called each deleted document on ACCS final phase, before deletion.
    #
    # Argument: target_file_path, source_file_path.
    # target_file_path is output file path (existing or non-existing.)
    @delete = HooksHolder.new "delete"

    # Called after all document were generated.
    #
    # Argument: this_time_processed([{source, dest, frontmatter}...])
    # this_time_processed has actually processed documents.
    # source is source file path, dest is generated file path.
    @post = HooksHolder.new "post"

    # Called before generating ACCS index.
    #
    # Argument: index, indexes.
    #
    # index is @index (frontmatter for ACCS index),
    # indexes is @indexes.
    @accs = HooksHolder.new "accs"
  end

  def load
    if File.file?("./.pbsimply-hooks.rb")
      require './.pbsimply-hooks.rb'
      PBSimply::Hooks.load_hooks(self) unless @hooks_loaded
      @hooks_loaded = true
    end
  end

  attr :pre
  attr :process
  attr :delete
  attr :post
  attr :accs

  attr :config
end
