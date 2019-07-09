class ImportZone < ApplicationService
  attr_reader :client, :credential, :hosted_zone_id, :user

  def initialize(user, hosted_zone_id, credential)
    @credential = credential
    @hosted_zone_id = hosted_zone_id
    @user = user
    @client = Route53Client.new(credential)
  end

  def call
    get_hosted_zone_response = client.get_hosted_zone(id: hosted_zone_id)
    hosted_zone = get_hosted_zone_response.hosted_zone
    root = hosted_zone.name
    user.zones.create(root: root, route53_hosted_zone_id: hosted_zone_id, credential: credential)
  rescue Aws::Route53::Errors::AccessDenied
    raise Credential::AccessDenied.new
  rescue Aws::Route53::Errors::NoSuchHostedZone
    raise NoSuchHostedZone.new
  end

  class NoSuchHostedZone < StandardError
  end
end