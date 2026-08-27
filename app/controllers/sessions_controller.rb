class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  # Freine les tentatives répétées : sans cette limite, un mot de passe
  # court finit par tomber sous un essai automatisé.
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: t("app.flash.trop_de_tentatives") }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      # Le message ne dit pas lequel des deux est faux : le préciser
      # permettrait de deviner quelles adresses existent.
      redirect_to new_session_path, alert: t("app.flash.identifiants_incorrects")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
