require 'dslimple'

class Dslimple::QueryBuilder
  attr_reader :queries
  attr_reader :expected_domains, :current_domains
  attr_reader :append_records, :change_records, :delete_records

  def initialize(current_domains, expected_domains)
    @current_domains = Hash[*current_domains.map { |domain| [domain.name, domain] }.flatten]
    @expected_domains = Hash[*expected_domains.map { |domain| [domain.name, domain] }.flatten]
  end

  def append_domains
    @append_domains ||= expected_domains.values.reject { |domain| current_domains.key?(domain.name) }
  end

  def delete_domains
    @delete_domains ||= current_domains.values.reject { |domain| expected_domains.key?(domain.name) }
  end

  def execute
    @append_records = append_domains.map(&:records_without_soa_ns).flatten
    @change_records = []
    @delete_records = delete_domains.map(&:records_without_soa_ns).flatten

    expected_domains.each_pair do |name, domain|
      execute_records(name, domain)
    end

    build_queries
  end

  def execute_records(domain_name, domain)
    current_domain = current_domains[domain_name]
    return unless current_domain

    current_records = current_domain.records_without_soa_ns.dup
    domain.records_without_soa_ns.each do |record|
      at = current_records.index { |current| current == record }
      current_record = at ? current_records.slice!(at) : nil
      like_record = current_records.find { |current| current === record }

      if !like_record && !current_record
        @append_records << record
      elsif like_record
        @change_records << [like_record, record]
        current_records.delete(like_record)
      end
    end
    @delete_records.concat(current_records)
  end

  def build_queries
    @queries = []

    append_domains.each do |domain|
      @queries << Dslimple::Query.new(:addition, :domain, domain)
    end

    append_records.each do |record|
      @queries << Dslimple::Query.new(:addition, :record, record.domain, record.to_params)
    end

    change_records.each do |old, new|
      @queries << Dslimple::Query.new(:modification, :record, new.domain, new.to_params.merge(id: old.id))
    end

    delete_records.each do |record|
      @queries << Dslimple::Query.new(:deletion, :record, record.domain, record.to_params)
    end

    delete_domains.each do |domain|
      @queries << Dslimple::Query.new(:deletion, :domain, domain)
    end

    @queries
  end

  def filtered_queries(options)
    queries.select do |query|
      (query.addition? && options[:addition]) ||
        (query.modification? && options[:modification]) ||
        (query.deletion? && options[:deletion])
    end
  end
end
