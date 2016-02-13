require 'dslimple/version'
require 'dslimple/domain'
require 'dslimple/record'
require 'dslimple/exporter'

module Dslimple
  ESCAPE_SINGLE_QUOTE_REGEXP = /[^\\]'/

  def self.escape_single_quote(string)
    string.gsub(ESCAPE_SINGLE_QUOTE_REGEXP) do |match|
      match[0] + "\\'"
    end
  end
end
