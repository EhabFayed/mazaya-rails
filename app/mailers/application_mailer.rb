class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "no-reply@mazaya.example.com")
  layout "mailer"
end
