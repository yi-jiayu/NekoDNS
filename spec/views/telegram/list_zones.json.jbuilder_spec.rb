require 'rails_helper'

RSpec.describe 'telegram/list_zones', type: :view do
  let(:chat_id) { 123 }
  let(:zones) { build_list(:zone, 2) }
  let(:formatted_zones) { 'formatted zones' }
  let(:expected_content) { {
    'method' => 'sendMessage',
    'chat_id' => chat_id,
    'text' => formatted_zones,
  } }

  before do
    allow(view).to receive(:format_zones).and_return(formatted_zones)
  end

  it 'renders a valid Telegram bot API sendMessage request' do
    assign(:chat_id, chat_id)
    assign(:zones, zones)

    render

    expect(JSON.parse(rendered)).to eq(expected_content)
  end
end