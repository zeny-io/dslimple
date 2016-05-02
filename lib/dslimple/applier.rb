require 'dslimple'
require 'pp'

class Dslimple::Applier
  OPERATION_COLORS = {
    addition: :green,
    modification: :yellow,
    deletion: :red
  }.freeze

  attr_reader :api_client, :account, :shell, :options

  def initialize(api_client, account, shell, options = {})
    @api_client = api_client
    @account = account
    @shell = shell
    @options = options
  end

  def execute
    dsl = Dslimple::DSL.new(options[:file], options)

    dsl.execute

    expected_domains = dsl.transform
    expected_domains.select! { |domain| options[:only].include?(domain.name) } if options[:only].any?

    @buildler = Dslimple::QueryBuilder.new(fetch_domains, expected_domains)
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

  def fetch_domains
    domains = api_client.domains.all_domains(account.id).data.map { |domain| Dslimple::Domain.new(domain.name, api_client, account, id: domain.id) }
    domains.each(&:fetch_records!)
    domains.select! { |domain| options[:only].include?(domain.name) } if options[:only].any?
    domains
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
      query.execute(api_client, account)
    end
  end

  def show_query(query)
    shell.say("#{shell.set_color(query.operation.to_s[0..2], OPERATION_COLORS[query.operation])} #{query}")
  end
end
