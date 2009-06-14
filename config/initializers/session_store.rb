# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_inotegration_session',
  :secret      => 'bc1eaf04025de6b992caad9213d659ccf53e404ff214c1abda9b64d812aafe5575f9df9b213b7cfcd0557a030e96c8e62a790bc5e50db8149e1cec1ca2575c74'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
