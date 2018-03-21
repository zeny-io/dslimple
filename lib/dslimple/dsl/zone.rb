require 'dslimple/dsl/record'
require 'dslimple/record'

class Dslimple::DSL::Zone
  attr_reader :name, :records

  def initialize(name, &block)
    @name = name
    @records = []

    instance_eval(&block)
  end

  def record(name = {}, options = {}, &block)
    if name.is_a?(Hash)
      options = options.merge(name)
      name = ''
    end
    options = options.merge(zone: @name, name: name)

    @records << Dslimple::DSL::Record.new(options, &block)
  end

  Dslimple::Record::RECORD_TYPES.map(&:downcase).each do |type|
    class_eval(<<-EOC)
      def #{type}_record(name = {}, options = {}, &block)
        record(name, options.merge(type: :#{type}), &block)
      end
    EOC
  end
end
