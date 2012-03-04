require 'yaml'

module Colloco
  module Util
    def load_configuration(file, name)
      if !File.exist?(file)
        puts "There's no configuration file at #{file}!"
        exit!
      end
      Colloco.const_set(name, YAML.load_file(file))
    end
  end
end
