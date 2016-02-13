require 'pathname'
require 'dslimple'

class Dslimple::DSL
  def initialize(file, context = {})
    @file = Pathname.new(file)
    @dir = @file.dirname
    @domains = []
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

  def domain(name, &block)
    @domains << Dslimple::DSL::Domain.new(name, &block)
  end

  def transform
    @domains.map do |domain|
      Dslimple::Domain.new(domain.name, nil).tap do |model|
        model.records = domain.records.map do |record|
          Dslimple::Record.new(model, record.options[:type], record.name, record.content, record.options)
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

require 'dslimple/dsl/domain'
require 'dslimple/dsl/record'
require 'dslimple/dsl/error'
