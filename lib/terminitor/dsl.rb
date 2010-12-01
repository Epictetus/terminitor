module Terminitor
  # This class parses the Termfile to fit the new Ruby Dsl Syntax
  class Dsl

    def initialize(path)
      file = File.read(path)
      @setup = []
      @windows = { 'default' => {:tabs => {}}}
      @_context = @windows['default'][:tabs]
      instance_eval(file)
    end

    # Contains all commands that will be run prior to the usual 'workflow'
    # e.g bundle install, setup forks, etc ...
    # setup "bundle install", "brew update"
    # setup { run('bundle install') }
    def setup(*commands, &block)
      if block_given?
        in_context @setup, &block
      else
        @setup.concat(commands)
      end
    end

    # sets command context to be run inside a specific window
    # window(:name => 'new window', :size => [80,30], :position => [9, 100]) { tab('ls','gitx') }
    # window { tab('ls', 'gitx') }
    def window(name =nil, options = nil, &block)
      options ||= {}
      options, name = name, nil if name.is_a?(Hash)    
      window_name = name || "window#{@windows.keys.size}"
      window_contents = @windows[window_name] = {:tabs => {}}
      window_contents[:options] = options unless options.empty?
      in_context window_contents[:tabs], &block
    end

    # stores command in context
    # run 'brew update'
    def run(command)
      @_context << command
    end

    # sets command context to be run inside specific tab
    # tab(:name => 'new tab', :settings => 'Grass') { run 'mate .' }
    # tab 'ls', 'gitx'
    def tab(name = nil, options = nil, *commands, &block)
      options ||= {}
      if block_given?
        options, name = name, nil if name.is_a?(Hash)    
        tab_name = name || "tab#{@_context.keys.size}"
        tab_contents = @_context[tab_name] = {:commands => []}
        tab_contents[:options] = options unless options.empty?
        in_context tab_contents[:commands], &block
      else
        tab_tasks = @_context["tab#{@_context.keys.size}"] = { :commands => [name] + [options] +commands}
      end
    end

    # Returns yaml file as Terminitor formmatted hash
    def to_hash
      { :setup => @setup, :windows => @windows }
    end

    private

    # in_context @setup, &block
    # in_context @tabs["name"], &block
    def in_context(context, &block)
      @_context, @_old_context = context, @_context
      instance_eval(&block)
      @_context = @_old_context
    end


  end
end
