if Rails.env.development? && defined?(Rails::Server)
  begin
    endpoint = URI('http://localhost:4040/api/tunnels/command_line')
    res = Net::HTTP.get_response(endpoint)
    tunnels = JSON.parse(res.body)
    local_uri = URI(tunnels['config']['addr'])
    remote_uri = URI(tunnels['public_url'])
    puts "initializers/ngrok.rb: found ngrok tunnel from #{local_uri} to #{remote_uri}"
    ngrok_host = remote_uri.host
    puts "initializers/ngrok.rb: adding #{ngrok_host} to config.hosts and setting config.ngrok_host"
    Rails.application.configure do
      config.ngrok_host = ngrok_host
      config.hosts << ngrok_host
    end
  rescue Errno::ECONNREFUSED
    puts "initializers/ngrok.rb: no ngrok tunnel detected"
  end
end
