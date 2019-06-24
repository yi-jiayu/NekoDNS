class DomainService
  class << self
    def create_domain(user, root)
      domain = Domain.create(user: user, root: root)
      response = client.create_hosted_zone(
          name: domain.root,
          caller_reference: domain.route53_create_hosted_zone_caller_reference,
          hosted_zone_config: {
              comment: comment_for(domain),
          },
      )
      domain.update(route53_hosted_zone_id: response.hosted_zone.id)
      domain
    end

    private

    def client
      @client ||= Aws::Route53::Client.new
    end

    def comment_for(domain)
      "Hosted zone created for #{domain.user.name} (#{domain.user.id}) by NekoDNS"
    end
  end
end