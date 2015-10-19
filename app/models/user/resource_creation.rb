# Create user-specific resources (servers, IP addresses, etc)
module ResourceCreation
  def create_server(specs = {})
    specs = server_defaults specs.to_hash.symbolize_keys # to_hash() is to coerce Rack::Test params away from Hashie
    specs[:template] = Template.find specs[:template].to_s unless specs[:template].is_a? Template
    server = Server.create specs
    server.worker.create_onapp_server
    server
  end

  def server_defaults(specs)
    specs[:template] ||= Template.find_an_ubuntu_template
    specs[:name] ||= "#{full_name}'s Server #{servers.count + 1}"
    specs[:hostname] ||= specs[:name].parameterize
    specs[:user] = self
    specs
  end
end
