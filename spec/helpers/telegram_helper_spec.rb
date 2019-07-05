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
  describe '#format_zones' do
    let(:zones) { build_list(:zone, 2) }
    let(:formatted_zones) { "#{zones[0].root}\n#{zones[1].root}" }

    it 'returns the formatted string' do
      expect(helper.format_zones(zones)).to eq(formatted_zones)
    end
  end
end
