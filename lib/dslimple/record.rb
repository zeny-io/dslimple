require 'dslimple'
require 'dnsimple'

class Dslimple::Record
  RECORD_TYPES = %w[A ALIAS CNAME MX SPF URL TXT NS SRV NAPTR PTR AAAA SSHFP HINFO POOL CAA]
  DEFAULT_REGIONS = ['global']

  attr_accessor :id, :zone, :name, :type, :ttl, :priority, :content, :regions, :system_record

  def initialize(attrs = {})
    attrs = normalize_attrs(attrs) if attrs.is_a?(Dnsimple::Struct::ZoneRecord)

    @id = attrs[:id]
    @zone = attrs[:zone_id] || attrs[:zone]
    @name = attrs[:name]
    @type = attrs[:type].to_s.downcase.to_sym
    @ttl = attrs[:ttl]
    @parent_id = attrs[:parent_id]
    @priority = attrs[:priority]
    @content = attrs[:content]
    @regions = attrs[:regions] || DEFAULT_REGIONS
    @system_record = attrs[:system_record]
  end

  def [](key)
    send(key)
  end

  def system_record?
    @system_record == true
  end

  def child_record?
    !@parent_id.nil?
  end

  def ==(other)
    other.is_a?(self.class) && hash == other.hash
  end

  def ===(other)
    other.is_a?(self.class) && %i[zone name type content].all? { |attr| send(attr).to_s == other.send(attr).to_s }
  end

  def hash
    [zone.to_s, name, type, ttl, priority, content, regions, !!system_record].hash
  end

  def to_dsl(options = {})
  [
    "  #{type.to_s.downcase}_record(#{name.inspect}) do",
    priority ? "    priority #{priority.inspect}" : "",
    ttl ? "    ttl #{ttl}" : "",
    regions != DEFAULT_REGIONS ? "    regions #{regions.inspect}" : "",
    "    content #{content.inspect}",
    "  end",
  ].reject(&:empty?).join("\n")
  end

  def to_params
    params = {
      id: @id,
      name: name,
      type: type.to_s.upcase,
      content: content,
      ttl: ttl,
      priority: priority,
      regions: regions,
    }
    params.delete(:regions)

    params
  end

  private

  def normalize_attrs(record)
    attrs = {}
    record.instance_variables.each do |var|
      attrs[:"#{var.to_s.sub(/^@/, '')}"] = record.instance_variable_get(var)
    end
    attrs
  end
end
