require 'dslimple'

class Dslimple::Query
  attr_reader :operation, :target, :zone, :params

  def initialize(operation, target, zone, params = {})
    @operation = operation
    @target = target
    @zone = zone
    @params = params
  end

  %i(addition modification deletion).each do |operation|
    class_eval(<<-EOC)
    def #{operation}?
      operation == :#{operation}
    end
    EOC
  end

  def to_s
    if target == :zone
      zone.to_s
    else
      %(#{params[:type].to_s.rjust(5)} #{params[:name].to_s.rjust(10)}.#{zone.to_s} (#{record_options.join(', ')}) "#{params[:content]}")
    end
  end

  def record_options
    options = []
    params.each_pair do |k, v|
      options << "#{k}: #{v}" if %i(ttl priority regions).include?(k) && v
    end
    options
  end

  def execute(api_client, account)
    __send__("execute_#{target}", api_client, account)
  end

  def execute_zone(api_client, account_id)
    case operation
    when :addition
      # TODO: Support registration
      # api_client.registrar.register_zone(account_id, zone, registrant_id: account.id, auto_renew: true)
    when :deletion
      # TODO: Support deletion
      # api_client.zones.delete_zone(account_id, zone)
    end
  end

  def execute_record(api_client, account_id)
    case operation
    when :addition
      api_client.zones.create_record(account_id, zone, params)
    when :modification
      api_client.zones.update_record(account_id, zone, params[:id], params)
    when :deletion
      api_client.zones.delete_record(account_id, zone, params[:id])
    end
  end
end
