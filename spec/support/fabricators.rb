Fabricator :server do
end

Fabricator :user do
  id 1
  email { sequence { |i| "rspec#{i}@cloud.net" } }
  full_name 'Rspec Test User'
  password 'abcd1234'
end
