require 'dslimple/dsl'

class Dslimple::DSL::Domain
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

    @records << Dslimple::DSL::Record.new(name, options, &block)
  end

  Dslimple::Record::RECORD_TYPES.each do |type|
    class_eval(<<-EOC)
      def #{type}_record(name = {}, options = {}, &block)
        record(name, options.merge(type: :#{type}), &block)
      end
    EOC
  end
end
