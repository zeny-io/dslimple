require 'pathname'
require 'dslimple'

class Dslimple::DSL
  def initialize(file, context = {})
    @file = Pathname.new(file)
    @dir = @file.dirname
    @zones = []
    @files = []

    @context = context
  end

  def execute
    evaluate(@file)
  end

  def require(path)
    if @dir.join(path).exist?
      evaluate(@dir.join(path))
    elsif @dir.join("#{path}.rb").exist?
      evaluate(@dir.join("#{path}.rb"))
    elsif @dir.join("#{path}.zone").exist?
      evaluate(@dir.join("#{path}.zone"))
    else
      Kernel.require(path)
    end
  end

  def evaluate(file)
    @files << file.to_s
    instance_eval(File.read(file), file.to_s)
  rescue ScriptError => e
    raise Dslimple::DSL::Error, "#{e.class}: #{e.message}", cleanup_backtrace(e.backtrace)
  rescue StandardError => e
    raise Dslimple::DSL::Error, "#{e.class}: #{e.message}", cleanup_backtrace(e.backtrace)
  end

  def zone(name, &block)
    @zones << Dslimple::DSL::Zone.new(name, &block)
  end

  def transform
    @zones.map do |zone|
      Dslimple::Zone.new(zone.name).tap do |model|
        model.records = zone.records.map do |record|
          Dslimple::Record.new(record)
        end
      end
    end
  end

  private

  def cleanup_backtrace(backtrace)
    return backtrace if @context[:debug]

    backtrace.select do |bt|
      path = bt.split(':')[0..-3].join(':')
      @files.include?(path)
    end
  end
end

require 'dslimple/dsl/zone'
require 'dslimple/dsl/record'
require 'dslimple/dsl/error'
