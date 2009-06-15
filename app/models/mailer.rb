class Mailer < ActionMailer::Base

  helper :application, :mailer

  def project_build_status(analysis)
    content_type "text/html"
    email_data = YAML::load_file(RAILS_ROOT + '/config/email.yml')['deliver_config']
    subject    "New build for #{analysis.project.nome}: #{analysis.situation_verbose}"
    recipients email_data['to']
    from       email_data['from']
    body       :analysis => analysis
  end

end
