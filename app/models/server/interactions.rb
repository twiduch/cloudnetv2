# End-user CRUD methods
# Basically just makes the API route methods very small
module Interactions
  def provision(specs = {})
    specs = new_server_defaults specs.to_hash.symbolize_keys # to_hash() is to coerce Rack::Test params away from Hashie
    specs[:template] = Template.find specs[:template].to_s unless specs[:template].is_a? Template
    update_attributes! specs
    worker.create_onapp_server
    self
  end

  def deprovision
    worker.destroy_onapp_server
  end

  private

  def new_server_defaults(specs)
    specs[:template] ||= Template.find_an_ubuntu_template
    specs[:name] ||= "#{user.full_name}'s Server #{user.servers.count + 1}"
    specs[:hostname] ||= specs[:name].parameterize
    specs[:user] = user
    specs
  end
end
