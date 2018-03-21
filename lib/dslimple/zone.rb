require 'dslimple'
require 'dslimple/record'

class Dslimple::Zone
  attr_reader :name
  attr_accessor :records

  def initialize(name)
    @name = name
    @records = []
  end

  def ==(other)
    other.is_a?(self.class) && hash == other.hash && records.hash == other.records.hash
  end

  def ===(other)
    other.is_a?(self.class) && hash == other.hash
  end

  def hash
    [name, records.map(&:hash)].hash
  end

  def to_s
    name
  end

  def to_dsl(options = {})
<<DSL
zone #{name.inspect} do
#{clean_records(options[:ignore]).map { |record| record.to_dsl(options) }.join("\n\n")}
end
DSL
  end

  def clean_records(ignores)
    ignores = [ignores].flatten.map(&:to_s)

    records.select do |record|
      next false if ignores.include?('system') && record.system_record?
      next false if ignores.include?('child') && record.child_record?
      true
    end
  end
end
