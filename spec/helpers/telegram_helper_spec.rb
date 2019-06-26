require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the TelegramHelper. For example:
#
# describe TelegramHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe TelegramHelper, type: :helper do
  describe '#format_domains' do
    let(:domains) { build_list(:domain, 2) }
    let(:formatted_domains) { "#{domains[0].root}\n#{domains[1].root}" }

    it 'returns the formatted string' do
      expect(helper.format_domains(domains)).to eq(formatted_domains)
    end
  end
end
