require 'dslimple'

class Dslimple::Domain
  attr_reader :name, :id
  attr_accessor :api_client, :account, :records

  def initialize(name, api_client, account, options = {})
    @name = name
    @id = options[:id]
    @api_client = api_client
    @account = account
    @records = []
  end

  def escaped_name
    Dslimple.escape_single_quote(name)
  end

  def records_without_soa_ns
    records.select { |record| record.type != :soa && record.type != :ns }
  end

  def fetch_records
    api_client.zones.all_records(account.id, name).data.map do |record|
      Dslimple::Record.new(self, record.type, record.name, record.content, ttl: record.ttl, priority: record.priority, id: record.id)
    end
  end

  def fetch_records!
    @records = fetch_records
    cleanup_records!
  end

  def cleanup_records!
    @records = Dslimple::Record.cleanup_records(records)
  end

  def ==(other)
    other.is_a?(Dslimple::Domain) && other.name == name
  end
  alias_method :eql, :==

  def to_dsl(options = {})
    <<"EOD"
domain '#{escaped_name}' do
#{(options[:soa_and_ns] ? records : records_without_soa_ns).map(&:to_dsl).join("\n")}end
EOD
  end
end
