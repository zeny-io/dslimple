require 'dslimple'
require 'dslimple/query'

class Dslimple::QueryBuilder
  attr_reader :queries, :options
  attr_reader :expected_zones, :current_zones
  attr_reader :append_records, :change_records, :delete_records

  def initialize(current_zones, expected_zones, options = {})
    @current_zones = Hash[*current_zones.map { |zone| [zone.name, zone] }.flatten]
    @expected_zones = Hash[*expected_zones.map { |zone| [zone.name, zone] }.flatten]
    @options = options
  end

  def append_zones
    @append_zones ||= expected_zones.values.reject { |zone| current_zones.key?(zone.name) }
  end

  def delete_zones
    @delete_zones ||= current_zones.values.reject { |zone| expected_zones.key?(zone.name) }
  end

  def execute
    @append_records = append_zones.map { |z| z.clean_records(options[:ignore]) }.flatten
    @change_records = []
    @delete_records = delete_zones.map { |z| z.clean_records(options[:ignore]) }.flatten

    expected_zones.each_pair do |name, zone|
      execute_records(name, zone)
    end

    build_queries
  end

  def execute_records(zone_name, zone)
    current_zone = current_zones[zone_name]
    return unless current_zone

    current_records = current_zone.clean_records(options[:ignore]).dup
    zone.clean_records(options[:ignore]).each do |record|
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

    append_zones.each do |zone|
      @queries << Dslimple::Query.new(:addition, :zone, zone)
    end

    append_records.each do |record|
      @queries << Dslimple::Query.new(:addition, :record, record.zone, record.to_params)
    end

    change_records.each do |old, new|
      @queries << Dslimple::Query.new(:modification, :record, new.zone, new.to_params.merge(id: old.id))
    end

    delete_records.each do |record|
      @queries << Dslimple::Query.new(:deletion, :record, record.zone, record.to_params)
    end

    delete_zones.each do |zone|
      @queries << Dslimple::Query.new(:deletion, :zone, zone)
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
