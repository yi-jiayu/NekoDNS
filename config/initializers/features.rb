class Features
  def self.enabled?(feature)
    Figaro.env.send(:"#{feature.to_s.upcase}_ENABLED") == 'true'
  end
end