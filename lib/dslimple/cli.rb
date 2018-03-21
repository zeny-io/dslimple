require 'thor'
require 'dnsimple'
require 'json'
require 'dslimple'
require 'dslimple/dsl'
require 'dslimple/client'

class Dslimple::CLI < Thor
  include Thor::Actions

  class_option :access_token, type: :string, aliases: %w(-a), desc: 'Your API token'
  class_option :sandbox, type: :boolean, default: ENV['DSLIMPLE_ENV'] == 'test', desc: 'Use sandbox API(at sandbox.dnsimple.com)'
  class_option :debug, type: :boolean, default: false

  desc 'export', 'Export domain specifications'
  method_option :only, type: :array, default: [], aliases: %w(-o), desc: 'Specify domains for export'
  method_option :file, type: :string, default: 'Zonefile', aliases: %w(-f), desc: 'Export zonefile path(- is stdout)'
  method_option :dir, type: :string, default: './zonefiles', aliases: %w(-d), desc: 'Export directory path for split'
  method_option :split, type: :boolean, default: false, aliases: %w(-s), desc: 'Export with split by domains'
  method_option :modeline, type: :boolean, default: false, aliases: %w(-m), desc: 'Export with modeline for Vim'
  method_option :ignore, type: :array, default: ['system', 'child'], desc: 'Ignore record types'
  def export
    require 'dslimple/exporter'
    fd = options[:file] == '-' ? STDOUT : File.open(options[:file].to_s, 'w')

    exporter = Dslimple::Exporter.new(client, fd, options)

    exporter.execute

    fd.close
  rescue => e
    rescue_from(e)
  end

  desc 'apply', 'Apply domain specifications'
  method_option :only, type: :array, default: [], aliases: %w(-o), desc: 'Specify domains for apply'
  method_option :dry_run, type: :boolean, default: false, aliases: %w(-d)
  method_option :ignore, type: :array, default: ['system', 'child'], desc: 'Ignore record types'
  method_option :file, type: :string, default: 'Zonefile', aliases: %w(-f), desc: 'Source Zonefile path'
  method_option :addition, type: :boolean, default: true, desc: 'Allow add records'
  method_option :modification, type: :boolean, default: true, desc: 'Allow modify records'
  method_option :deletion, type: :boolean, default: true, desc: 'Allow delete records'
  method_option :yes, type: :boolean, default: false, aliases: %w(-y), desc: 'Do not confirm on before apply'
  def apply
    require 'dslimple/applier'
    applier = Dslimple::Applier.new(client, self, options)

    applier.execute
  rescue => e
    rescue_from(e)
  rescue Dslimple::DSL::Error => e
    rescue_from(e)
  end

  private

  def client
    @aclient ||= Dslimple::Client.new(
      access_token: options[:api_token] || ENV['DSLIMPLE_API_TOKEN'] || ENV['DSLIMPLE_ACCESS_TOKEN'],
      sandbox: options[:sandbox]
    )
  end

  def rescue_from(e)
    raise e if options[:debug]

    case e
    when Dnsimple::AuthenticationError
      error(set_color(e.message, :red, :bold))
    when Dnsimple::RequestError
      error(set_color("#{e.message}: #{JSON.parse(e.response.body)['message']}", :yellow, :bold))
    when Dslimple::DSL::Error
      error(set_color(e.message, :yellow, :bold))
    else
      error(set_color("#{e.class}: #{e.message}", :red, :bold))
    end
    e.backtrace.each do |bt|
      say("  #{set_color('from', :green)} #{bt}")
    end
    exit 1
  end
end
