require 'pathname'
require 'dslimple'

class Dslimple::Exporter
  attr_reader :client, :file, :options, :zones, :onlies

  def initialize(client, file, options)
    @client = client
    @file = file
    @options = options
    @onlies = [options[:only]].flatten.map(&:to_s).reject(&:empty?)
  end

  def execute
    @zones = client.all_zones(with_records: true)

    if options[:split] && options[:dir]
      split_export(file, options[:dir])
    else
      export(file, clean_zones(zones))
    end
  end

  def export(fd, export_zones)
    write_modeline(fd)
    fd.puts export_zones.map { |zone| zone.to_dsl(options) }.join("\n")
  end

  def split_export(fd, dir)
    dir = Pathname.new(dir)
    Dir.mkdir(dir.to_s) unless dir.directory?

    write_modeline(file)
    clean_zones(zones).each do |zone|
      zonefile = dir.join("#{zone.name}.zone")
      File.open(zonefile, 'w') do |fd|
        export(fd, [zone])
      end
      fd.puts "require '#{zonefile.relative_path_from(Pathname.new(fd.path).dirname)}'"
    end
  end

  def write_modeline(fd)
    fd << "# -*- mode: ruby -*-\n# vi: set ft=ruby :\n\n" if options[:modeline]
  end

  protected

  def clean_zones(zones)
    return zones if onlies.empty?

    zones.select do |zone|
      onlies.include?(zone.name)
    end
  end
end
