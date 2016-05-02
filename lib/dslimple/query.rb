require 'dslimple'

class Dslimple::Query
  attr_reader :operation, :target, :domain, :params

  def initialize(operation, target, domain, params = {})
    @operation = operation
    @target = target
    @domain = domain
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
    if target == :domain
      domain.name.to_s
    else
      %(#{params[:record_type].to_s.rjust(5)} #{params[:name].to_s.rjust(10)}.#{domain.name} (#{record_options.join(', ')}) "#{params[:content]}")
    end
  end

  def record_options
    options = []
    params.each_pair do |k, v|
      options << "#{k}: #{v}" if %i(ttl prio).include?(k) && v
    end
    options
  end

  def execute(api_client, account)
    __send__("execute_#{target}", api_client, account)
  end

  def execute_domain(api_client, account)
    case operation
    when :addition
      api_client.registrar.register_domain(account.id, domain.name, registrant_id: account.id, auto_renew: true)
    when :deletion
      api_client.domains.delete_domain(account.id, domain.name)
    end
  end

  def execute_record(api_client, account)
    case operation
    when :addition
      api_client.zones.create_record(account.id, domain.name, params)
    when :modification
      api_client.zones.update_record(account.id, domain.name, params[:id], params)
    when :deletion
      api_client.zones.delete_record(account.id, domain.name, params[:id])
    end
  end
end
