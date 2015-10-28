require 'vcr'

# Use the .env file to compile the list of sensitive data that should not be recorded in
# cassettes
def sensitive_strings
  contents = File.read "#{Cloudnet.root}/.env"
  words = contents.split(/\s+/)
  words = filter_env_keys words
  # Turn the key/value pairs into an actual hash
  Hash[words]
end

def filter_env_keys(words)
  # Only interested in words with an '=' in them
  words.reject! { |w| !w.include? '=' }
  # Create a list of key/value pairs
  words.map! { |w| w.split('=') }
  # Ignore empty values and keys marked as safe
  words.delete_if { |w| w[1].blank? || safe_env_keys.include?(w[0]) }
end

def safe_env_keys
  [
    'ONAPP_CLOUDNET_ROLE'
  ]
end

# Because some API requests prepend URIs with http://`user:pass`@domain.com then domain matching
# doesn't work. So provide a protocol-less version of URIs for matching.
def extract_domain(string)
  URI.parse(string).host
rescue
  string
end

VCR.configure do |c|
  c.hook_into :faraday
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.configure_rspec_metadata!

  # Filter out sensitive data and replace with ERB interpolation.
  # Assuming that you're using .env to store your sensitive app credentials, then you can
  # use VCR's `filter_sensitive_data` method to convert occurrences of those credentials
  # to `<%= ENV['#{key}'] %>` in your recorded VCR cassettes.
  sensitive_strings.each do |key, sensitive_string|
    # NB: intentionally not interpolating ENV[] as #{ENV[]}. We actually *want* '<%= ENV[*] %>' to
    # appear in VCR's ERB-enabled YML files
    manifestations = {
      extract_domain(sensitive_string) => "<%= extract_domain ENV[\"#{key}\"] %>",
      CGI.escape(sensitive_string)     => "<%= CGI.escape ENV[\"#{key}\"] %>",
      sensitive_string                 => "<%= ENV[\"#{key}\"] %>"
    }
    manifestations.each_pair do |string, replacement|
      c.filter_sensitive_data(replacement) { string }
    end
  end

  # When recording a new cassette, we have the opportunity to query the live Onapp API to find out
  # what version it is. So raise an error if there is a version mismatch.
  c.before_http_request(:recordable?) do
    onapp_api_version = OnappAPI.admin(
      :get,
      '/version',
      # Add a signature to be super specific that it is *only* this request we want VCR to ignore
      vcr_ignore: true
    )['version']
    if onapp_api_version != Cloudnet::ONAPP_API_VERSION
      fail '`Cloudnet::ONAPP_API_VERSION` must match live Onapp API version being tested.'
    end
  end

  # Prevent the above HTTP request to check the OnApp API version from generating a useless cassette
  c.ignore_request do |request|
    URI(request.uri).query == 'vcr_ignore=true'
  end

  c.default_cassette_options = {
    record: :once,
    erb: :true,
    allow_playback_repeats: true,
    match_requests_on: [:method, :path, :query]
  }
end
