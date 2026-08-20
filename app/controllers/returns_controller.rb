# Enregistrement d'un retour au comptoir.
#
# L'écran est volontairement plus court que celui du prêt : une seule
# recherche, une seule liste, un bouton par ligne. Le bibliothécaire a le
# livre en main, il n'a rien à décider.
#
# La recherche ne porte que sur les prêts en cours. Chercher dans tout le
# catalogue ferait remonter des livres qui sont sur l'étagère, donc pas
# concernés par un retour.
class ReturnsController < ApplicationController
  RESULTS_LIMIT = 25

  def new
    # Retour qui vient d'être enregistré : l'écran de succès prend la place.
    @confirmed_loan = Loan.find_by(id: params[:confirmed_loan_id])
    return if @confirmed_loan

    @query = params[:q].to_s
    @loans = Loan.open
                 .includes(:book, :member)
                 .search(@query)
                 .oldest_due_first
                 .limit(RESULTS_LIMIT)

    # Sert à distinguer « rien d'emprunté » de « rien qui corresponde ».
    @nothing_on_loan = Loan.open.none?
  end

  def create
    loan = Loan.find(params[:loan_id])

    unless loan.open?
      return redirect_to new_return_path, alert: "Ce livre a déjà été rendu."
    end

    loan.return!
    redirect_to new_return_path(confirmed_loan_id: loan.id)
  end
end
