Fabricator :user do
  id 1
  email { sequence { |i| "rspec#{i}@cloud.net" } }
  full_name 'Rspec Test User'
  password 'abcd1234'
  onapp_username 'tester'
  onapp_password 'password'
  cloudnet_api_key 'apikey264254'
end

Fabricator :datacentre do
  id '123'
  label 'Cloud.net Budget US Dallas Zone'
  coords [32.7767, 96.797]
end

Fabricator :template do
  id '123'
  datacentre
  label 'Arch Linux 2012.08 x86'
  os 'linux'
  os_distro 'archlinux'
end

Fabricator :server do
  user
  template
  name 'Testing server'
  hostname 'testing-server'
end
