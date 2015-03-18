# Be sure to restart your server when you modify this file.
require 'securerandom'
# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
def find_secure_token
  ::Configuration[:secret_token] = SecureRandom.hex(64) unless ::Configuration[:secret_token]
  ::Configuration[:secret_token]
rescue
  # Just to ensure that we can run migrations and create the configurations table
  nil
end

def find_secure_key_base
  ::Configuration[:secret_key_base] = SecureRandom.hex(64) unless ::Configuration[:secret_key_base]
  ::Configuration[:secret_key_base]
rescue
  # Just to ensure that we can run migrations and create the configurations table
  nil
end

Neighborly::Application.config.secret_token = find_secure_token
Neighborly::Application.config.secret_key_base = find_secure_key_base
#4954c738f4c8ec3225b858f723470ba8b84c120c4b195872b80e906aaca31f91c8462b14e4be7e73a7b6ce76533583332e975bd629d6ada8237af1d08facef7e
