require 'dslimple'

class Dslimple::Record
  RECORD_TYPES = %i(a alias cname mx spf url txt ns srv naptr ptr aaaa sshfp hinfo pool).freeze
  ALIAS_PREFIX = /\AALIAS for /
  SPF_PREFIX = /\Av=spf1 /

  attr_reader :domain, :type, :name, :id, :ttl, :priority, :content

  def self.cleanup_records(records)
    records = records.dup
    alias_records = records.select(&:alias?)
    spf_records = records.select(&:spf?)
    txt_records = records.select { |record| record.like_spf? || record.like_alias? }

    txt_records.each do |record|
      reject = record.like_spf? ? spf_records.any? { |r| record.eql_spf?(r) } : alias_records.any? { |r| record.eql_alias?(r) }

      records.delete(record) if reject
    end

    records
  end

  RECORD_TYPES.each do |type|
    class_eval(<<-EOC)
      def #{type}?
        type == :#{type}
      end
    EOC
  end

  def initialize(domain, type, name, content, options = {})
    @domain = domain
    @type = type.to_s.downcase.to_sym
    @name = name
    @content = content
    @ttl = options[:ttl]
    @priority = options[:priority]
    @id = options[:id]
  end

  def escaped_name
    Dslimple.escape_single_quote(name)
  end

  def escaped_content
    Dslimple.escape_single_quote(content)
  end

  def like_spf?
    txt? && content.match(SPF_PREFIX)
  end

  def like_alias?
    txt? && content.match(ALIAS_PREFIX)
  end

  def eql_spf?(spf_record)
    spf_record.ttl == ttl && spf_record.content == content
  end

  def eql_alias?(alias_record)
    alias_record.ttl == ttl && content == "ALIAS for #{alias_record.content}"
  end

  def ==(other)
    other.is_a?(Dslimple::Record) && other.domain == domain && other.hash == hash
  end
  alias_method :eql, :==

  def ===(other)
    other.is_a?(Dslimple::Record) && other.domain == domain && other.rough_hash == rough_hash
  end

  def hash
    "#{type}:#{name}:#{content}:#{ttl}:#{priority}"
  end

  def rough_hash
    "#{type}:#{name}:#{content}"
  end

  def to_dsl_options
    options = []
    options << "'#{escaped_name}'" unless escaped_name.empty?
    options << "ttl: #{ttl}" if ttl
    options << "priority: #{priority}" if priority
    options.join(', ')
  end

  def to_dsl
    <<"EOD"
  #{type}_record #{to_dsl_options} do
    '#{escaped_content}'
  end
EOD
  end

  def to_params
    {
      id: id,
      record_type: type.to_s.upcase,
      name: name,
      content: content,
      ttl: ttl,
      prio: priority
    }
  end

  def inspect
    "<Dslimple::Record #{type.to_s.upcase} #{name}: #{content}>"
  end
end
