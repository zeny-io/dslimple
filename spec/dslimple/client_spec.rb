require 'spec_helper'
require 'dslimple/client'

RSpec.describe Dslimple::Client do
  subject(:client) { Dslimple::Client.new(sandbox: true) }

  describe "#account_id" do
    subject(:account_id) { client.account_id }

    it { is_expected.to_not be_nil }
    it { is_expected.to eq(223) }
  end

  describe "#all_zones" do
    subject(:all_zones) { client.all_zones }

    it { is_expected.to all(be_a(Dslimple::Zone)) }
  end

  describe "#all_records" do
    subject(:all_records) { client.all_records('zeny.io') }

    it { is_expected.to all(be_a(Dslimple::Record)) }
  end
end
