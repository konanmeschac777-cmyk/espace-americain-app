# Enregistrement d'un retour au comptoir.
#
# Un seul écran : une recherche, puis dès qu'elle désigne un prêt précis
# (choisi dans une liste, ou seul résultat), l'aperçu du retour avec sa
# date d'échéance et le geste pour le confirmer. Il n'y a pas d'écran de
# succès dédié : un retour réussi ramène au tableau de bord (23), avec son
# bandeau de confirmation.
#
# La recherche ne porte que sur les prêts en cours. Chercher dans tout le
# catalogue ferait remonter des livres qui sont sur l'étagère, donc pas
# concernés par un retour.
class ReturnsController < ApplicationController
  RESULTS_LIMIT = 25

  def new
    @query = params[:q].to_s

    @loan = Loan.open.includes(:book, :member).find_by(id: params[:loan_id]) if params[:loan_id].present?

    if @loan.nil? && @query.present?
      resultats = Loan.open.includes(:book, :member).search(@query).oldest_due_first.limit(RESULTS_LIMIT)
      @loan = resultats.sole rescue nil
      @loans = resultats unless @loan
    end

    # Sert à distinguer « rien d'emprunté » de « rien qui corresponde ».
    @nothing_on_loan = Loan.open.none? if @loan.nil? && @loans.nil?
  end

  def create
    loan = Loan.find(params[:loan_id])

    unless loan.open?
      return redirect_to new_return_path, alert: t("app.flash.livre_deja_rendu")
    end

    member = loan.member
    loan.return!

    if loan.returned_late?
      if ActiveModel::Type::Boolean.new.cast(params[:waive_suspension])
        member.lift_suspension!
      else
        member.update!(suspended_until: Date.current + loan.days_late)
      end
    end

    message = t("app.flash.retour_enregistre", titre: loan.book.title, nom: member.full_name)
    redirect_to tableau_de_bord_path, notice: message
  end
end
