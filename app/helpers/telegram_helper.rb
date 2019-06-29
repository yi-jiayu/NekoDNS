module TelegramHelper
  def format_domains(domains)
    domains.map(&:root).join("\n")
  end

  def format_records(domain)
    records = domain.records.map { |r| "#{r.type}\t#{r.name}\t#{r.value}\t#{r.ttl}" }.join("\n")
    "Records for #{domain.root}\n```\n#{records}\n```"
  end

  def set_record_in_progress(domain, record)
    <<~TEXT.chomp
      Setting record for domain #{domain.root}
      *Type:* #{record.type}
      *Name:* #{record.name}
      *Value:* #{record.value}
      *TTL:* #{record.ttl}
    TEXT
  end

  def show_flash
    [flash.alert, flash.notice].compact.join("\n")
  end
end
