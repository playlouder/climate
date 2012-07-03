require 'climate'
require 'yaml'

module Example

  class Parent < Climate::Command
    name 'example'
    description <<DESC
Example app to show usage of subcommands.

Implements a contrived cli for querying and updating a yaml config file.
DESC

    opt  :log,         'Whether to log to stdout', :default => false
    opt  :config_file, 'Path to config file',      :default => 'config_file', :type => :string,
    :short => 'f'

    opt  :create,      'Create the config file if it is missing',
    :default => false
  end

  module Common

    def config_yaml
      parent = ancestor(Parent)
      filename = parent.options[:config_file]

      if not File.exists?(filename)
        if parent.options[:create]
          File.open(filename, 'w') {|f| YAML.dump({}, f) }
        else
          raise Climate::ExitException.new(self, "No config file: #{filename}")
        end

      end

      YAML.load_file(filename)
    end

    def save_config(hash)
      parent = ancestor(Parent)
      filename = parent.options[:config_file]

      File.open(filename, 'w') {|f| YAML.dump(hash, f) }
    end
  end

  class Show < Climate::Command
    include Common
    name 'show'
    subcommand_of Parent

    description <<DESC
Show configuration values.

Here is another paragraph explaining that you can show a value or multiple
values that exist in the config file by supplying or not supplying an argument
DESC

    arg :key, 'config key to show', :required => false

    def run
      yaml = config_yaml

      if key = arguments[:key]
        stdout.puts("#{key}: #{yaml[key]}")
      else
        yaml.keys.sort.each do |key|
          stdout.puts("#{key}: #{yaml[key]}")
        end
      end
    end
  end

  class Set < Climate::Command
    include Common
    name 'set'
    subcommand_of Parent
    description <<DESC
Set a configuration value.

This opens the config file and sets a value to it, or clears a value if you do
not supply a second argument.
DESC
    arg :key, 'config key to set'
    arg :value, 'value to set', :required => false

    def run
      yaml = config_yaml

      if arguments.has_key?(:value)
        yaml[arguments[:key]] = arguments[:value]
      else
        yaml.delete(arguments[:key])
      end

      save_config(yaml)
    end
  end
end

Climate.with_standard_exception_handling do
  Example::Parent.run(ARGV)
end