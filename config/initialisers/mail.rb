require 'mail'

Mail.defaults do
  delivery_method(
    :smtp,
    address: ENV['SMTP_DOMAIN'],
    port: ENV['SMTP_PORT'],
    enable_starttls_auto: true,
    user_name: ENV['SMTP_USER'],
    password: ENV['SMTP_PASSWORD'],
    authentication: ENV['SMTP_AUTH_METHOD'],
    domain: 'cloud.net'
  )
end
