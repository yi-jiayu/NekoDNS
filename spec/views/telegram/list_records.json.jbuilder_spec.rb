require 'rails_helper'

RSpec.describe 'telegram/list_records', type: :view do
  let(:chat_id) { 123 }
  let(:domain) { build(:domain, root: 'example.com') }
  let(:records) { [
    build(:record, type: 'NS', name: 'example.com', value: 'ns1.example.com', ttl: 300),
    build(:record, type: 'A', name: 'subdomain.example.com', value: '127.0.0.1', ttl: 300),
  ] }
  let(:formatted_records) { <<~TEXT
    Records for example.com
    ```
    NS\texample.com\tns1.example.com\t300
    A\tsubdomain.example.com\t127.0.0.1\t300
    ```
  TEXT
  }
  let(:expected_content) { {
    'method' => 'sendMessage',
    'chat_id' => chat_id,
    'text' => formatted_records.strip,
    'parse_mode' => 'markdown',
  } }

  before do
    allow(domain).to receive(:records).and_return(records)
  end

  it 'renders the correct Telegram bot API request' do
    assign(:chat_id, chat_id)
    assign(:domain, domain)

    render

    expect(JSON.parse(rendered)).to eq(expected_content)
  end
end