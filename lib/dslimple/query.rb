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
      "#{domain.name}"
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

  def execute(api_client)
    __send__("execute_#{target}", api_client)
  end

  def execute_domain(api_client)
    case operation
    when :addition
      api_client.domains.create(name: domain.name)
    when :deletion
      api_client.domains.delete(domain.name)
    end
  end

  def execute_record(api_client)
    case operation
    when :addition
      api_client.domains.create_record(domain.name, params)
    when :modification
      api_client.domains.update_record(domain.name, params[:id], params)
    when :deletion
      api_client.domains.delete_record(domain.name, params[:id])
    end
  end
end
