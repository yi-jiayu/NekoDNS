class CreateZone < ApplicationService
  def initialize(user, root, credential = nil)
    @user = user
    @root = root
    @credential = credential
    @client = Route53Client.new(credential)
  end

  def call
    Zone.transaction do
      zone = Zone.find_or_create_by(user: @user, root: @root)
      raise ZoneAlreadyExists.new if zone.route53_hosted_zone_id.present?

      response = @client.create_hosted_zone(
        name: zone.root,
        caller_reference: zone.route53_create_hosted_zone_caller_reference,
        hosted_zone_config: {
          comment: "Hosted zone created for #{zone.user.name} (#{zone.user.id}) by NekoDNS",
        },
      )
      zone.update(route53_hosted_zone_id: response.hosted_zone.id, credential: @credential)
      zone
    rescue Aws::Route53::Errors::InvalidDomainName
      raise InvalidDomainName.new
    end
  end

  class ZoneAlreadyExists < StandardError
    def message
      'Zone already exists'
    end
  end

  class InvalidDomainName < StandardError
    def message
      'Invalid domain name'
    end
  end
end
