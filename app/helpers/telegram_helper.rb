module TelegramHelper
  def format_domains(domains)
    domains.map(&:root).join("\n")
  end
end
