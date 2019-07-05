module TelegramHelper
  def format_zones(zones)
    zones.map(&:root).join("\n")
  end

  def format_records(zone)
    records = zone.records.map { |r| "#{r.type}\t#{r.name}\t#{r.value}\t#{r.ttl}" }.join("\n")
    "Records for #{zone.root}\n```\n#{records}\n```"
  end

  def set_record_in_progress(zone, record)
    <<~TEXT.chomp
      Setting record for zone #{zone.root}
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
