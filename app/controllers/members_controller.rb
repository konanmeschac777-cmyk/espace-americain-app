class MembersController < ApplicationController
  # Prolonge l'abonnement d'un an. Le paiement se fait au comptoir et
  # n'est pas enregistré ici : l'application ne connaît que la date.
  def renew
    member = Member.find(params[:id])
    member.renew_membership!

    message = "Abonnement de #{member.full_name} prolongé jusqu'au #{l(member.expires_on, format: :long)}."

    if params[:redirect_to_loan]
      redirect_to new_loan_path(member_id: member.id), notice: message
    else
      redirect_back fallback_location: root_path, notice: message
    end
  end
end
