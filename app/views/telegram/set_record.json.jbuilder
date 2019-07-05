json.method 'sendMessage'
json.chat_id @chat_id
json.text set_record_in_progress(@zone, @record)
json.parse_mode 'markdown'