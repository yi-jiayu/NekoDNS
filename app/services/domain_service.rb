class DomainService
  def self.create_domain(user, root)
    Domain.transaction do
      Domain.create(user: user, root: root).tap do |domain|
        Record.create(domain: domain, type: 'SOA', name: 'soa record')
        Record.create(domain: domain, type: 'NS', name: 'ns record 1')
        Record.create(domain: domain, type: 'NS', name: 'ns record 2')
      end
    end
  end
end