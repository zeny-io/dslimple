require 'dslimple/dsl'

class Dslimple::DSL::Record
  attr_reader :name, :content, :options

  def initialize(name, options = {}, &block)
    @name = name
    @options = options

    returned_content = instance_eval(&block)
    @content ||= returned_content
  end

  def priority(n)
    @options[:priority] = n.to_s.to_i
  end

  def ttl(n)
    @options[:ttl] = n.to_s.to_i
  end

  def content(c = nil)
    c ? @content = c : @content
  end
end
