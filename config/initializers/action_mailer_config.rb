if RAILS_ENV != 'test' && File.exists?("#{RAILS_ROOT}/config/email.yml")
  email_settings = YAML::load(File.open("#{RAILS_ROOT}/config/email.yml"))
  ActionMailer::Base.smtp_settings = email_settings[RAILS_ENV] unless email_settings[RAILS_ENV].nil?
end
