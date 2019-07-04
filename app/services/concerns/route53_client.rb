module Route53Client
  def self.new(credential)
    if credential.nil?
      Aws::Route53::Client.new
    else
      credential_provider = Aws::AssumeRoleCredentials.new(role_arn: credential.arn,
                                                           role_session_name: 'NekoDNS',
                                                           external_id: credential.external_id)
      Aws::Route53::Client.new(credentials: credential_provider)
    end
  rescue Aws::STS::Errors::AccessDenied
    raise Credential::AccessDenied
  end
end