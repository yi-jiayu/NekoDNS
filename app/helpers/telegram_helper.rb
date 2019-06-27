module TelegramHelper
  def format_domains(domains)
    domains.map(&:root).join("\n")
  end

  def format_records(domain)
    records = domain.records.map { |r| "#{r.type}\t#{r.name}\t#{r.value}\t#{r.ttl}" }.join("\n")
    "Records for #{domain.root}\n```\n#{records}\n```"
  end
end
