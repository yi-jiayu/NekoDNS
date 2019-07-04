class CreateZone < ApplicationService
  def initialize(user, root, credential = nil)
    @user = user
    @root = root
    @credential = credential
    @client = Route53Client.new(credential)
  end

  def call
    domain = Domain.find_or_create_by(user: @user, root: @root)
    raise ZoneAlreadyExists.new if domain.route53_hosted_zone_id.present?

    response = @client.create_hosted_zone(
      name: domain.root,
      caller_reference: domain.route53_create_hosted_zone_caller_reference,
      hosted_zone_config: {
        comment: "Hosted zone created for #{domain.user.name} (#{domain.user.id}) by NekoDNS",
      },
    )
    domain.update(route53_hosted_zone_id: response.hosted_zone.id, credential: @credential)
    domain
  end

  class ZoneAlreadyExists < StandardError
    def message
      'Zone already exists'
    end
  end
end
