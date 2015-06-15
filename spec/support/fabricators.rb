Fabricator :server do
end

Fabricator :user do
  email { sequence { |i| "rspec#{i}@cloud.net" } }
  full_name 'Rspec Test User'
end
