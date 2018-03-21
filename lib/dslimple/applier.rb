require 'dslimple'
require 'dslimple/query_builder'

class Dslimple::Applier
  OPERATION_COLORS = {
    addition: :green,
    modification: :yellow,
    deletion: :red
  }.freeze

  attr_reader :client, :shell, :options

  def initialize(client, shell, options = {})
    @client = client
    @shell = shell
    @options = options
  end

  def execute
    dsl = Dslimple::DSL.new(options[:file], options)

    dsl.execute

    expected_zones = dsl.transform
    expected_zones.select! { |zone| options[:only].include?(zone.name) } unless options[:only].empty?

    @buildler = Dslimple::QueryBuilder.new(fetch_zones, expected_zones, options)
    @buildler.execute
    queries = @buildler.filtered_queries(options)

    if queries.empty?
      shell.say('No Changes', :bold)
      return
    end

    show_plan(queries)

    return if options[:dry_run] || !(options[:yes] || shell.yes?("Apply #{queries.size} changes. OK?(y/n) >"))

    apply(queries)
  end

  def fetch_zones
    zones = client.all_zones(with_records: true)
    zones.select! { |zone| options[:only].include?(zone.name) } if options[:only].any?
    zones
  end

  def show_plan(queries)
    shell.say('Changes', :bold)
    queries.each do |query|
      show_query(query)
    end
  end

  def apply(queries)
    shell.say('Apply', :bold)
    queries.each do |query|
      show_query(query)
      query.execute(client, client.account_id)
    end
  end

  def show_query(query)
    shell.say("#{shell.set_color(query.operation.to_s[0..2], OPERATION_COLORS[query.operation])} #{query}")
  end
end
