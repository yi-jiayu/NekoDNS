require 'rails_helper'

RSpec.describe 'telegram/list_domains', type: :view do
  let(:chat_id) { 123 }
  let(:domains) { build_list(:domain, 2) }
  let(:formatted_domains) { 'formatted domains' }
  let(:expected_content) { {
    'method' => 'sendMessage',
    'chat_id' => chat_id,
    'text' => formatted_domains,
  } }

  before do
    allow(view).to receive(:format_domains).and_return(formatted_domains)
  end

  it 'renders a valid Telegram bot API sendMessage request' do
    assign(:chat_id, chat_id)
    assign(:domains, domains)

    render

    expect(JSON.parse(rendered)).to eq(expected_content)
  end
end