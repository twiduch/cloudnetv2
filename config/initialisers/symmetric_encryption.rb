# For generating a new config file;
#
# require 'symmetric-encryption'
# SymmetricEncryption.generate_symmetric_key_files('config/symmetric-encryption.yml', 'production')

require 'symmetric-encryption'

SymmetricEncryption.load!(
  File.join(Cloudnet.root, 'config/symmetric-encryption.yml'),
  Cloudnet.environment
)
