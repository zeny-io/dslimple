require 'dslimple/dsl'

class Dslimple::DSL::Record
  ATTRIBUTES = %i[zone name type content ttl priority regions]
  attr_accessor *ATTRIBUTES

  def initialize(name, options = {}, &block)
    options.each_pair do |key, val|
      break unless respond_to?("#{key}=")

      send("#{key}=", val)
    end

    returned_content = instance_eval(&block)
    @content ||= returned_content
  end

  ATTRIBUTES.each do |attr|
    define_method(attr) do |v = nil|
      v ? instance_variable_set("@#{attr}", v) : instance_variable_get("@#{attr}")
    end

    define_method("#{attr}=") do |v|
      instance_variable_set("@#{attr}", v)
    end
  end

  def region(v = nil)
    self.regions = [v].flatten
  end

  def region=(v)
    self.regions = [v].flatten
  end
end
