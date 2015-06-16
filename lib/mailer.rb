# Make sure the mailers are already loaded
Cloudnet.recursive_require 'app/email'

# Piece together an email from mailer_method, template and defaults
class BuildEmail
  TEMPLATE_PATH = File.join Cloudnet.root, 'app', 'email', 'templates'

  attr_reader :email

  def initialize(mailer_method, *args, &block)
    builder = self
    @email = Mail.new do
      from 'noreply@cloud.net'
      # Call the original mailer method DSL commands after these commands to overwrite them
      mailer_method.bind(self).call(*args, &block)
      body builder.html(mailer_method, binding)
    end
  end

  # Use the instance variables from `mailer_method` to build the email body from a template.
  def html(mailer_method, context)
    file_name = "#{mailer_method.name}.erb"
    template_path = File.join TEMPLATE_PATH, file_name
    erb = ERB.new File.read template_path
    erb.result context
  end
end

# Redefine all the mailer methods to run in the context of `Mail.new {}`
module Mailers
  class << self
    def before(*names)
      names.each do |name|
        mailer_method = instance_method(name)
        define_method(name) do |*args, &block|
          BuildEmail.new(mailer_method, *args, &block).email
        end
      end
    end
  end

  user_created_mailers = instance_methods(false)
  before(*user_created_mailers)
end

# Shorthand for accessing mailers. Eg; `Email.welcome(user).deliver`
class Email
  extend Mailers
end
