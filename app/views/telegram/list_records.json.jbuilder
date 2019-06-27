json.method 'sendMessage'
json.chat_id @chat_id
json.text format_records(@domain)
json.parse_mode 'markdown'