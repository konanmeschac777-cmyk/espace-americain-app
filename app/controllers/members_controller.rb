class MembersController < ApplicationController
  # Réinscrit pour un an. L'adhésion est gratuite : il n'y a aucun montant
  # à saisir, seulement une autorisation à enregistrer.
  def renew
    member = Member.find(params[:id])
    member.renew_membership!

    message = "#{member.full_name} est réinscrit jusqu'au #{l(member.expires_on, format: :long)}."

    if params[:redirect_to_loan]
      redirect_to new_loan_path(member_id: member.id), notice: message
    else
      redirect_back fallback_location: root_path, notice: message
    end
  end
end
