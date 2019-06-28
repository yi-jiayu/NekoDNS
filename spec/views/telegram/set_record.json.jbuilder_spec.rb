require 'rails_helper'

RSpec.describe 'telegram/set_record', type: :view do
  let(:chat_id) { 123 }
  let(:domain) { build(:domain) }
  let(:record) { build(:record) }
  let(:text) { <<~TEXT.chomp
    Setting record for domain #{domain.root}
    *Type:* #{record.type}
    *Name:* #{record.name}
    *Value:* #{record.value}
    *TTL:* #{record.ttl}
  TEXT
  }
  let(:expected_content) { {
    'method' => 'sendMessage',
    'chat_id' => chat_id,
    'text' => text,
    'parse_mode' => 'markdown',
  } }


  it 'renders the correct Telegram bot API request' do
    assign(:chat_id, chat_id)
    assign(:domain, domain)
    assign(:record, record)

    render

    expect(JSON.parse(rendered)).to eq(expected_content)
  end
end