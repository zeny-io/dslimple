require 'dslimple/version'
require 'dslimple/domain'
require 'dslimple/record'
require 'dslimple/dsl'
require 'dslimple/query'
require 'dslimple/query_builder'
require 'dslimple/exporter'
require 'dslimple/applier'

module Dslimple
  ESCAPE_SINGLE_QUOTE_REGEXP = /[^\\]'/

  def self.escape_single_quote(string)
    string.gsub(ESCAPE_SINGLE_QUOTE_REGEXP) do |match|
      match[0] + "\\'"
    end
  end
end
