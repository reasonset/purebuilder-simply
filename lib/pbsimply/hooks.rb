#!/usr/bin/ruby

# Hooks is new in PureBuilder Simply 2.2.
# Hooks object has instance variables for each timing.
# 
class PBSimply::Hooks

  # Timing object class.
  class HooksHolder
    def initialize
      @hooks = []
    end

    def <<(proc)
      @hooks << proc
    end

    alias :add :<<

    def run(arg)
      @hooks.each do |proc|
        begin
          proc.(arg)
        rescue
          puts "*** HOOKS PROC ERROR ***"
          raise
        end
      end
    end
  end

  def initialize(pbsimply)
    @pbsimply = pbsimply

    # Called first phase before generate. This hooks called before blessing.
    #
    # Argument: frontmatter, procdoc.
    # procdoc is processing source document path.
    @pre = HooksHolder

    # Called after document was generated.
    # 
    # Argument: outpath, frontmatter, procdoc.
    # outpath is generated final document path. You can read output result.
    # procdoc is source document path before generate.
    @process = HooksHolder.new

    # Called each deleted document on ACCS final phase, before deletion.
    #
    # Argument: target_file_path.
    # target_file_path is deleting file path.
    @delete = HooksHolder.new

    # Called after all document were generated.
    #
    # Argument: this_time_processed([{source, dest}...])
    # this_time_processed has actually processed documents.
    # source is source file path, dest is generated file path.
    @post = HooksHolder.new

    # Called after all document were generated on ACCS mode.
    @accs = HooksHolder.new
  end

  def load
    if File.file?("./.pbsimply-hooks.rb")
      require './.pbsimply-hooks.rb'
      PBSimply::Hooks.load_hooks(self)
    end
  end

  attr :pre
  attr :process
  attr :delete
  attr :post
  attr :accs
end