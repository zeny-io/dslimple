require 'dnsimple'
require 'dslimple/zone'
require 'dslimple/record'

class Dslimple::Client < Dnsimple::Client
  SANDBOX_URL = 'https://api.sandbox.dnsimple.com'
  USER_AGENT = "dslimple v#{Dslimple::VERSION}"

  def initialize(sandbox: false, **options)
    options[:base_url] = SANDBOX_URL if sandbox
    options[:user_agent] = USER_AGENT

    options[:access_token] ||= ENV['DNSIMPLE_ACCESS_TOKEN']

    super(options)
  end

  def account_id
    return @account_id if instance_variable_defined?(:@account_id)

    whoami = identity.whoami.data
    @account_id = whoami.user&.id
    @account_id = whoami.account.id if whoami.account

    @account_id
  end

  def all_zones(with_records: false)
    response = zones.list_zones(account_id)

    zones = []
    while response
      zones = zones + response.data.map do |zone|
        zone = Dslimple::Zone.new(zone.name)
        zone.records = all_records(zone) if with_records
        zone
      end

      response = if response.page < response.total_pages
                   zones.list_zones(account_id, page: response.page + 1)
                 else
                   nil
                 end
    end
    zones
  end

  def all_records(zone)
    zone = zone.name if zone.is_a?(Dslimple::Zone)
    response = zones.list_zone_records(account_id, zone)

    records = []
    while response
      records = records + response.data.map do |record|
        record = Dslimple::Record.new(record)
        record.zone = zone
        record
      end

      response = if response.page < response.total_pages
                   zones.list_zone_records(account_id, zone, page: response.page + 1)
                 else
                   nil
                 end
    end
    records
  end
end
