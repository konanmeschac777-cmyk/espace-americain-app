class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Réinitialise ton mot de passe — American Shelf", to: user.email_address
  end
end
