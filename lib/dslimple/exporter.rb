require 'pathname'
require 'dslimple'

class Dslimple::Exporter
  attr_reader :api_client, :options, :domains

  def initialize(api_client, options)
    @api_client = api_client
    @options = options
    @domains = []
  end

  def execute
    fetch_domains
    domains.select! { |domain| options[:only].include?(domain.name) } unless options[:only].empty?

    if options[:split] && options[:dir]
      split_export(options[:dir], options[:file])
    else
      export(options[:file], domains)
    end
  end

  def fetch_domains
    @domains = api_client.domains.list.map { |domain| Dslimple::Domain.new(domain.name, api_client) }
    domains.each(&:fetch_records!)
  end

  def export(file, export_domains)
    File.open(file.to_s, 'w') do |fd|
      write_modeline(fd)
      fd.puts export_domains.map { |domain| domain.to_dsl(options) }.join("\n")
    end
  end

  def split_export(dir, file)
    dir = Pathname.new(dir)
    file = Pathname.new(file)
    Dir.mkdir(dir.to_s) unless dir.directory?

    File.open(file.to_s, 'w') do |fd|
      write_modeline(fd)
      domains.each do |domain|
        domainfile = dir.join(domain.name)
        export(domainfile, [domain])
        fd.puts "require '#{domainfile.relative_path_from(file.dirname)}'"
      end
    end
  end

  def write_modeline(fd)
    fd << "# -*- mode: ruby -*-\n# vi: set ft=ruby :\n\n" if options[:modeline]
  end
end
