begin
  ActionMailer::Base.default 'Content-Transfer-Encoding' => 'quoted-printable'

  if Rails.env.production?
    ActionMailer::Base.smtp_settings = {
    address: 'smtp.mandrillapp.com',
    port: '587',
    authentication: :plain,
    user_name: Configuration[:mandrill_user_name],
    password: Configuration[:mandrill],
    domain: 'www.contribute.de'
    }
    ActionMailer::Base.delivery_method = :smtp
  end
  if Rails.env.development?
    ActionMailer::Base.smtp_settings = {
    address: 'smtp.mandrillapp.com',
    port: '587',
    authentication: :plain,
    user_name: Configuration[:mandrill_user_name],
    password: Configuration[:mandrill],
    domain: 'www.contribute.de'
    }
    ActionMailer::Base.delivery_method = :smtp
  end
rescue
  nil
end
