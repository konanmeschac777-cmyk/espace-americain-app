# Enregistrement d'un prêt au comptoir.
#
# L'écran se parcourt en trois étapes : trouver l'abonné, trouver l'ouvrage,
# confirmer. L'étape en cours se déduit de l'URL et non d'une session : le
# bibliothécaire peut revenir en arrière, recharger la page ou reprendre sur
# un autre téléphone sans rien perdre.
class LoansController < ApplicationController
  RESULTS_LIMIT = 8

  # Les quatre vues de la liste des emprunts. La clé arrive par l'URL, ce
  # qui rend chaque filtre partageable et rechargeable.
  FILTRES = {
    "tous"    => { libelle: "Tous",        portee: -> { Loan.open } },
    "cours"   => { libelle: "En cours",    portee: -> { Loan.on_time } },
    "bientot" => { libelle: "Bientôt dus", portee: -> { Loan.due_soon } },
    "retard"  => { libelle: "En retard",   portee: -> { Loan.overdue } }
  }.freeze

  def index
    @filtre = FILTRES.key?(params[:filtre]) ? params[:filtre] : "tous"

    @compteurs = FILTRES.transform_values { |f| f[:portee].call.count }
    @loans = FILTRES.fetch(@filtre)[:portee].call
                    .includes(:book, :member)
                    .oldest_due_first
  end

  def renew
    loan = Loan.find(params[:id])

    if loan.renew!
      redirect_back fallback_location: loans_path,
                    notice: "« #{loan.book.title} » est prolongé jusqu'au #{l(loan.due_on, format: :long)}."
    else
      redirect_back fallback_location: loans_path,
                    alert: "Ce prêt a déjà été renouvelé une fois, il ne peut plus l'être."
    end
  end

  def new
    # Prêt qui vient d'être enregistré : l'écran de succès prend alors
    # toute la place, il n'y a rien d'autre à montrer.
    @confirmed_loan = Loan.find_by(id: params[:confirmed_loan_id])
    return if @confirmed_loan

    @member = Member.find_by(id: params[:member_id])
    @book   = Book.find_by(id: params[:book_id])

    @member_query = params[:member_q].to_s
    @book_query   = params[:book_q].to_s

    @members = search_members if @member.nil?
    @books   = search_books   if @member.present? && @book.nil?

    @loan = Loan.prepare(book: @book, member: @member) if ready_to_confirm?
  end

  def create
    @member = Member.find(params[:member_id])
    @book   = Book.find(params[:book_id])

    reason = blocking_reason(@member, @book)
    if reason
      return redirect_to new_loan_path(member_id: @member.id, book_id: @book.id),
                         alert: blocking_message(reason)
    end

    @loan = Loan.prepare(book: @book, member: @member)

    if @loan.save
      redirect_to new_loan_path(confirmed_loan_id: @loan.id)
    else
      redirect_to new_loan_path(member_id: @member.id, book_id: @book.id),
                  alert: @loan.errors.full_messages.to_sentence
    end
  end

  private

  def ready_to_confirm? = @member.present? && @book.present?

  def search_members
    return Member.none if @member_query.blank?

    Member.search(@member_query).by_name.limit(RESULTS_LIMIT)
  end

  def search_books
    return Book.none if @book_query.blank?

    Book.active.search(@book_query).by_title.limit(RESULTS_LIMIT)
  end

  # Rassemble les quatre motifs de blocage : les trois qui viennent de
  # l'abonné, et celui qui vient de l'ouvrage.
  def blocking_reason(member, book)
    member.borrow_block_reason || (:no_copy_available unless book.available?)
  end

  def blocking_message(reason)
    case reason
    when :suspended          then "Cet abonné est suspendu, le prêt est impossible."
    when :membership_expired then "L'abonnement est expiré, il doit être prolongé avant tout prêt."
    when :already_borrowing  then "Cet abonné a déjà un livre en cours."
    when :no_copy_available  then "Plus aucun exemplaire disponible pour cet ouvrage."
    end
  end

end
