class Features
  def self.enabled?(feature)
    return true if Rails.env.test?

    Figaro.env.send(:"#{feature.to_s.upcase}_ENABLED") == 'true'
  end
end