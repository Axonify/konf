require 'yaml'
require 'erb'

class Konf < Hash
  class NotFound  < StandardError; end
  class Invalid   < StandardError; end
  
  def initialize(source, root = nil)
    hash = case source
    when Hash
      source
    else
      # https://stackoverflow.com/questions/71191685/visit-psych-nodes-alias-unknown-alias-default-psychbadalias
      yaml = begin
               YAML.load(ERB.new(File.read(source.to_s)).result, aliases: true)
             rescue ArgumentError
               YAML.load(ERB.new(File.read(source.to_s)).result)
             end
      if File.exists?(source.to_s) && yaml =
        yaml.to_hash
      else
        raise Invalid, "Invalid configuration input: #{source}"
      end
    end
    if root
      hash = hash[root] or raise NotFound, "No configuration found for '#{root}'"
    end
    self.replace hash
  end
  
  def method_missing(name, *args, &block)
    key = name.to_s
    if key.gsub!(/\?$/, '')
      has_key? key
    else
      raise NotFound, "No configuration found for '#{name}'" unless has_key?(key)
      value = fetch key
      value.is_a?(Hash) ? Konf.new(value) : value
    end
  end
  
end