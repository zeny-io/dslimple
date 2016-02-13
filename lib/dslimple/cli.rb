require 'thor'
require 'dnsimple'
require 'dslimple'

class Dslimple::CLI < Thor
  include Thor::Actions

  SANDBOX_API_ENDPOINT = 'https://api.sandbox.dnsimple.com'.freeze
  USER_AGENT = "DSLimple: Simple CLI DNSimple client(v#{Dslimple::VERSION})".freeze

  class_option :email, type: :string, aliases: %w(-e), desc: 'Your E-Mail address'
  class_option :api_token, type: :string, aliases: %w(-t), desc: 'Your API token'
  class_option :domain_token, type: :string, aliases: %w(-dt), desc: 'Your Domain API token'
  class_option :sandbox, type: :boolean, default: ENV['DLSIMPLE_ENV'] == 'test', desc: 'Use sandbox API(at sandbox.dnsimple.com)'
  class_option :debug, type: :boolean, default: false

  desc 'export', 'Export domain specifications'
  method_option :only, type: :array, default: [], aliases: %w(-o), desc: 'Specify domains for export'
  method_option :file, type: :string, default: 'Domainfile', aliases: %w(-f), desc: 'Export filename'
  method_option :dir, type: :string, default: './domainfiles', aliases: %w(-d), desc: 'Export directory name'
  method_option :split, type: :boolean, default: false, aliases: %w(-s), desc: 'Export with split by domains'
  method_option :modeline, type: :boolean, default: false, aliases: %w(-m), desc: 'Export with modeline for Vim'
  method_option :soa_and_ns, type: :boolean, default: false, desc: 'Export without SOA and NS records'
  def export
    exporter = Dslimple::Exporter.new(api_client, options)

    exporter.execute
  rescue => e
    rescue_from(e)
  end

  desc 'apply', 'Apply domain specifications'
  method_option :dry_run, type: :boolean, default: false, aliases: %w(-d)
  method_option :exclude_soa_and_ns, type: :boolean, default: true, desc: 'Apply without SOA and NS records'
  method_option :yes, type: :boolean, default: false, aliases: %w(-y), desc: 'Do not confirm on before apply'
  def apply
  rescue => e
    rescue_from(e)
  end

  desc 'diff LEFT-SPEC RIGHT-SPEC', 'Show difference 2 domain specifications'
  def diff(_left, _right)
  rescue => e
    rescue_from(e)
  end

  desc 'whoami', 'Show your user informaion'
  def whoami
    user = api_client.users.user
    say(user.email)
  rescue => e
    rescue_from(e)
  end

  private

  def api_client
    @api_client ||= Dnsimple::Client.new(
      username: options[:email] || ENV['DLSIMPLE_EMAIL'],
      api_token: options[:api_token] || ENV['DLSIMPLE_API_TOKEN'],
      domain_api_token: options[:domain_token] || ENV['DLSIMPLE_DOMAIN_TOKEN'],
      api_endpoint: options[:sandbox] ? SANDBOX_API_ENDPOINT : nil,
      user_agent: USER_AGENT
    )
  end

  def rescue_from(e)
    raise e if options[:debug]

    case e
    when Dnsimple::AuthenticationError
      error(set_color(e.message, :red, :bold))
    when Dnsimple::RequestError
      error(set_color(e.message, :yellow, :bold))
    else
      error(set_color("#{e.class}: #{e.message}", :red, :bold))
    end
    exit 1
  end
end
